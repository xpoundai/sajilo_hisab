import uuid
from django.db import models
from django.contrib.auth.models import User
from core.models import Business


class BusinessUser(models.Model):
    ROLE_CHOICES = [
        ('admin', 'Admin'),
        ('manager', 'Manager'),
        ('staff', 'Staff'),
        ('viewer', 'Viewer'),
    ]

    DEFAULT_PERMISSIONS = {
        'admin': ['all'],
        'manager': [
            'view_dashboard', 'create_transactions', 'view_inventory',
            'manage_inventory', 'view_parties', 'manage_parties',
            'view_payments', 'manage_payments', 'view_reports', 'manage_banks',
        ],
        'staff': [
            'view_dashboard', 'create_transactions', 'view_inventory',
            'view_parties', 'manage_parties',
        ],
        'viewer': ['view_dashboard', 'view_inventory', 'view_parties'],
    }

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    business = models.ForeignKey(Business, on_delete=models.CASCADE, related_name='users')
    auth_user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='business_user')
    name = models.CharField(max_length=255)
    phone = models.CharField(max_length=20)
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default='staff')
    permissions = models.JSONField(default=list)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        unique_together = ['business', 'phone']

    def __str__(self):
        return f"{self.name} ({self.role}) - {self.business.name}"

    def has_permission(self, perm):
        if 'all' in self.permissions:
            return True
        return perm in self.permissions

    def save(self, *args, **kwargs):
        if not self.permissions:
            self.permissions = self.DEFAULT_PERMISSIONS.get(self.role, [])
        super().save(*args, **kwargs)
