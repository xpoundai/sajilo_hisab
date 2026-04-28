from django.contrib import admin
from .models import Business, PlatformUser, ActivityLog, Notification

@admin.register(Business)
class BusinessAdmin(admin.ModelAdmin):
    list_display = ['name', 'owner_name', 'phone', 'plan', 'status', 'created_at']
    list_filter = ['plan', 'status']
    search_fields = ['name', 'owner_name', 'phone']

@admin.register(PlatformUser)
class PlatformUserAdmin(admin.ModelAdmin):
    list_display = ['user', 'is_platform_admin', 'created_at']

@admin.register(ActivityLog)
class ActivityLogAdmin(admin.ModelAdmin):
    list_display = ['action', 'target', 'module', 'user_name', 'timestamp']
    list_filter = ['module']

@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ['title', 'type', 'priority', 'business', 'is_read', 'created_at']
    list_filter = ['type', 'priority', 'is_read']
    search_fields = ['title', 'message']
    readonly_fields = ['id', 'created_at']
