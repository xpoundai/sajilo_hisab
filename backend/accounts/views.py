from rest_framework import status, generics
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from django.db import transaction as db_transaction

from .models import BusinessUser
from .serializers import (
    LoginSerializer, AdminLoginSerializer, RegisterSerializer,
    BusinessUserSerializer, BusinessUserCreateSerializer,
    BusinessUserUpdateSerializer, UserProfileSerializer,
)
from core.models import Business, PlatformUser, ActivityLog
from core.permissions import BusinessUserPermission, CanManageUsers, IsBusinessAdmin
from core.mixins import BusinessScopedMixin
from payments.models import CashBook


def get_tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {
        'access': str(refresh.access_token),
        'refresh': str(refresh),
    }


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        # We can accept either 'phone' or 'identifier' to stay backward compatible
        identifier = request.data.get('identifier') or request.data.get('phone')
        password = request.data.get('password')

        if not identifier or not password:
            return Response({'error': 'Please provide identifier and password.'}, status=status.HTTP_400_BAD_REQUEST)

        user = authenticate(username=identifier, password=password)
        if not user:
            return Response({'error': 'Invalid credentials.'}, status=status.HTTP_401_UNAUTHORIZED)

        # Check if platform admin
        if hasattr(user, 'platform_user') and user.platform_user.is_platform_admin:
            tokens = get_tokens_for_user(user)
            return Response({
                'tokens': tokens,
                'user': {
                    'id': str(user.platform_user.id),
                    'username': user.username,
                    'is_platform_admin': True,
                },
                'is_platform_admin': True,
            })

        # Otherwise it must be a business user
        if not hasattr(user, 'business_user'):
            return Response({'error': 'No account found.'}, status=status.HTTP_403_FORBIDDEN)

        bu = user.business_user
        if not bu.is_active:
            return Response({'error': 'Account is deactivated.'}, status=status.HTTP_403_FORBIDDEN)

        if bu.business.status == 'suspended':
            return Response({'error': 'Business account is suspended.'}, status=status.HTTP_403_FORBIDDEN)

        tokens = get_tokens_for_user(user)
        profile = UserProfileSerializer(bu).data

        return Response({
            'tokens': tokens,
            'user': profile,
            'is_platform_admin': False,
        })


class AdminLoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = AdminLoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        username = serializer.validated_data['username']
        password = serializer.validated_data['password']

        user = authenticate(username=username, password=password)
        if not user:
            return Response({'error': 'Invalid credentials.'}, status=status.HTTP_401_UNAUTHORIZED)

        if not hasattr(user, 'platform_user') or not user.platform_user.is_platform_admin:
            return Response({'error': 'Not a platform admin.'}, status=status.HTTP_403_FORBIDDEN)

        tokens = get_tokens_for_user(user)
        return Response({
            'tokens': tokens,
            'user': {
                'id': str(user.platform_user.id),
                'username': user.username,
                'is_platform_admin': True,
            },
            'is_platform_admin': True,
        })


class RegisterView(APIView):
    permission_classes = [AllowAny]

    @db_transaction.atomic
    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        # Create business
        business = Business.objects.create(
            name=data['business_name'],
            owner_name=data['owner_name'],
            phone=data['phone'],
            email=data.get('email', ''),
            address=data.get('address', ''),
            plan='basic',
            status='trial',
        )

        # Create auth user
        auth_user = User.objects.create_user(
            username=data['phone'],
            password=data['password'],
            first_name=data['owner_name'],
        )

        # Create business user as admin
        bu = BusinessUser.objects.create(
            business=business,
            auth_user=auth_user,
            name=data['owner_name'],
            phone=data['phone'],
            role='admin',
            permissions=['all'],
        )

        # Create cashbook
        CashBook.objects.create(business=business, balance=0)

        # Log activity
        ActivityLog.objects.create(
            business=business,
            user_name=bu.name,
            action='Business Registered',
            target=business.name,
            module='system',
        )

        tokens = get_tokens_for_user(auth_user)
        profile = UserProfileSerializer(bu).data

        return Response({
            'tokens': tokens,
            'user': profile,
            'is_platform_admin': False,
        }, status=status.HTTP_201_CREATED)


class LogoutView(APIView):
    def post(self, request):
        try:
            refresh_token = request.data.get('refresh')
            if refresh_token:
                token = RefreshToken(refresh_token)
                token.blacklist()
        except Exception:
            pass
        return Response({'message': 'Logged out successfully.'})


class TokenRefreshView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        refresh = request.data.get('refresh')
        if not refresh:
            return Response({'error': 'Refresh token required.'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            token = RefreshToken(refresh)
            return Response({
                'access': str(token.access_token),
                'refresh': str(token),
            })
        except Exception as e:
            return Response({'error': 'Invalid or expired token.'}, status=status.HTTP_401_UNAUTHORIZED)


class ProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if hasattr(request.user, 'platform_user') and request.user.platform_user.is_platform_admin:
            return Response({
                'id': str(request.user.platform_user.id),
                'username': request.user.username,
                'is_platform_admin': True,
            })
        if hasattr(request.user, 'business_user'):
            return Response({
                'user': UserProfileSerializer(request.user.business_user).data,
                'is_platform_admin': False,
            })
        return Response({'error': 'No profile found.'}, status=status.HTTP_404_NOT_FOUND)


# Business User Management
class UserListCreateView(BusinessScopedMixin, generics.ListCreateAPIView):
    queryset = BusinessUser.objects.all()
    permission_classes = [IsAuthenticated, CanManageUsers]

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return BusinessUserCreateSerializer
        return BusinessUserSerializer

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx['business'] = self.get_business()
        return ctx

    @db_transaction.atomic
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        business = self.get_business()
        auth_user = User.objects.create_user(
            username=data['phone'],
            password=data['password'],
            first_name=data['name'],
        )

        permissions = data.get('permissions') or BusinessUser.DEFAULT_PERMISSIONS.get(data['role'], [])
        bu = BusinessUser.objects.create(
            business=business,
            auth_user=auth_user,
            name=data['name'],
            phone=data['phone'],
            role=data['role'],
            permissions=permissions,
        )

        ActivityLog.objects.create(
            business=business,
            user_name=request.user.business_user.name,
            action='User Created',
            target=bu.name,
            module='users',
        )

        return Response(BusinessUserSerializer(bu).data, status=status.HTTP_201_CREATED)


class UserDetailView(BusinessScopedMixin, generics.RetrieveUpdateDestroyAPIView):
    queryset = BusinessUser.objects.all()
    permission_classes = [IsAuthenticated, CanManageUsers]
    serializer_class = BusinessUserUpdateSerializer

    def destroy(self, request, *args, **kwargs):
        user = self.get_object()
        if user.id == request.user.business_user.id:
            return Response({'error': 'Cannot delete yourself.'}, status=status.HTTP_400_BAD_REQUEST)
        user.auth_user.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
