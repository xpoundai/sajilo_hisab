from django.contrib import admin
from .models import BusinessUser

@admin.register(BusinessUser)
class BusinessUserAdmin(admin.ModelAdmin):
    list_display = ['name', 'phone', 'role', 'business', 'is_active', 'created_at']
    list_filter = ['role', 'is_active']
    search_fields = ['name', 'phone']
