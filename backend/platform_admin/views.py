import platform
import sys
from datetime import datetime

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Sum, Count, Q
from django.utils import timezone

from core.models import Business, PlatformUser, ActivityLog
from core.permissions import IsPlatformAdmin
from accounts.models import BusinessUser
from transactions.models import Transaction
from core.serializers import BusinessSerializer


class PlatformStatsView(APIView):
    permission_classes = [IsAuthenticated, IsPlatformAdmin]

    def get(self, request):
        total_businesses = Business.objects.count()
        active = Business.objects.filter(status='active').count()
        trial = Business.objects.filter(status='trial').count()
        suspended = Business.objects.filter(status='suspended').count()
        total_users = BusinessUser.objects.count()
        total_transactions = Transaction.objects.count()

        return Response({
            'total_businesses': total_businesses,
            'active_businesses': active,
            'trial_businesses': trial,
            'suspended_businesses': suspended,
            'total_users': total_users,
            'total_transactions': total_transactions,
            'plan_distribution': {
                'basic': Business.objects.filter(plan='basic').count(),
                'pro': Business.objects.filter(plan='pro').count(),
                'premium': Business.objects.filter(plan='premium').count(),
            },
        })


class PlatformBusinessListView(APIView):
    permission_classes = [IsAuthenticated, IsPlatformAdmin]

    def get(self, request):
        search = request.query_params.get('search', '')
        status_filter = request.query_params.get('status', '')
        plan_filter = request.query_params.get('plan', '')

        qs = Business.objects.all()
        if search:
            qs = qs.filter(Q(name__icontains=search) | Q(owner_name__icontains=search) | Q(phone__icontains=search))
        if status_filter:
            qs = qs.filter(status=status_filter)
        if plan_filter:
            qs = qs.filter(plan=plan_filter)

        businesses = []
        for b in qs[:100]:
            businesses.append({
                'id': str(b.id),
                'name': b.name,
                'owner_name': b.owner_name,
                'phone': b.phone,
                'email': b.email,
                'address': b.address,
                'plan': b.plan,
                'status': b.status,
                'user_count': b.users.count(),
                'transaction_count': b.transactions.count(),
                'created_at': b.created_at.isoformat(),
            })

        return Response({'businesses': businesses})


class PlatformBusinessDetailView(APIView):
    permission_classes = [IsAuthenticated, IsPlatformAdmin]

    def patch(self, request, pk):
        try:
            business = Business.objects.get(id=pk)
        except Business.DoesNotExist:
            return Response({'error': 'Business not found.'}, status=404)

        allowed_fields = ['status', 'plan']
        for field in allowed_fields:
            if field in request.data:
                setattr(business, field, request.data[field])
        business.save()

        ActivityLog.objects.create(
            user_name=request.user.username,
            action='Business Updated',
            target=business.name,
            module='system',
            metadata={'changes': {k: v for k, v in request.data.items() if k in allowed_fields}},
        )

        return Response(BusinessSerializer(business).data)


class PlatformUserListView(APIView):
    permission_classes = [IsAuthenticated, IsPlatformAdmin]

    def get(self, request):
        search = request.query_params.get('search', '')
        users = BusinessUser.objects.select_related('business', 'auth_user').all()

        if search:
            users = users.filter(Q(name__icontains=search) | Q(phone__icontains=search))

        role_counts = {
            'admin': users.filter(role='admin').count(),
            'manager': users.filter(role='manager').count(),
            'staff': users.filter(role='staff').count(),
            'viewer': users.filter(role='viewer').count(),
        }

        user_list = []
        for u in users[:100]:
            user_list.append({
                'id': str(u.id),
                'name': u.name,
                'phone': u.phone,
                'role': u.role,
                'business_name': u.business.name,
                'business_id': str(u.business.id),
                'is_active': u.is_active,
                'created_at': u.created_at.isoformat(),
            })

        return Response({
            'role_counts': role_counts,
            'users': user_list,
        })


class SystemInfoView(APIView):
    permission_classes = [IsAuthenticated, IsPlatformAdmin]

    def get(self, request):
        return Response({
            'version': '1.0.0',
            'environment': 'development',
            'python_version': sys.version,
            'platform': platform.platform(),
            'database': 'SQLite (dev) / PostgreSQL (prod)',
            'region': 'Asia/Kathmandu',
            'uptime': 'N/A',
            'last_backup': 'N/A',
            'system_health': 'healthy',
            'active_users_24h': BusinessUser.objects.filter(is_active=True).count(),
            'total_api_calls_24h': 'N/A',
        })
