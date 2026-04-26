from rest_framework import serializers
from django.contrib.auth.models import User
from .models import BusinessUser
from core.models import Business


class LoginSerializer(serializers.Serializer):
    phone = serializers.CharField(max_length=20)
    password = serializers.CharField(write_only=True)


class AdminLoginSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=150)
    password = serializers.CharField(write_only=True)


class RegisterSerializer(serializers.Serializer):
    business_name = serializers.CharField(max_length=255)
    owner_name = serializers.CharField(max_length=255)
    phone = serializers.CharField(max_length=20)
    email = serializers.EmailField(required=False, allow_blank=True)
    address = serializers.CharField(required=False, allow_blank=True, default='')
    password = serializers.CharField(write_only=True, min_length=6)
    confirm_password = serializers.CharField(write_only=True)

    def validate(self, data):
        if data['password'] != data['confirm_password']:
            raise serializers.ValidationError({'confirm_password': 'Passwords do not match.'})
        if User.objects.filter(username=data['phone']).exists():
            raise serializers.ValidationError({'phone': 'An account with this phone already exists.'})
        return data


class BusinessUserSerializer(serializers.ModelSerializer):
    business_name = serializers.CharField(source='business.name', read_only=True)

    class Meta:
        model = BusinessUser
        fields = [
            'id', 'name', 'phone', 'role', 'permissions',
            'is_active', 'created_at', 'business_name',
        ]
        read_only_fields = ['id', 'created_at', 'business_name']


class BusinessUserCreateSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=255)
    phone = serializers.CharField(max_length=20)
    role = serializers.ChoiceField(choices=BusinessUser.ROLE_CHOICES)
    permissions = serializers.ListField(child=serializers.CharField(), required=False)
    password = serializers.CharField(write_only=True, min_length=6)

    def validate_phone(self, value):
        business = self.context['business']
        if BusinessUser.objects.filter(business=business, phone=value).exists():
            raise serializers.ValidationError('A user with this phone already exists in this business.')
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError('This phone is already registered.')
        return value


class BusinessUserUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = BusinessUser
        fields = ['name', 'role', 'permissions', 'is_active']


class UserProfileSerializer(serializers.ModelSerializer):
    business = serializers.SerializerMethodField()

    class Meta:
        model = BusinessUser
        fields = ['id', 'name', 'phone', 'role', 'permissions', 'is_active', 'business']

    def get_business(self, obj):
        return {
            'id': str(obj.business.id),
            'name': obj.business.name,
            'plan': obj.business.plan,
            'status': obj.business.status,
            'owner_name': obj.business.owner_name,
            'phone': obj.business.phone,
            'email': obj.business.email,
            'address': obj.business.address,
            'pan_number': obj.business.pan_number,
        }
