from rest_framework import serializers
from .models import Business, ActivityLog, Notification


class BusinessSerializer(serializers.ModelSerializer):
    class Meta:
        model = Business
        fields = '__all__'
        read_only_fields = ['id', 'created_at', 'updated_at']


class BusinessUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Business
        fields = ['name', 'owner_name', 'phone', 'email', 'address', 'pan_number']


class ActivityLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = ActivityLog
        fields = '__all__'
        read_only_fields = ['id', 'timestamp']


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = [
            'id', 'type', 'priority', 'title', 'message',
            'is_read', 'data', 'created_at',
        ]
        read_only_fields = ['id', 'created_at']
