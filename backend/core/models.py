import uuid
from django.db import models
from django.contrib.auth.models import User


class Business(models.Model):
    PLAN_CHOICES = [('basic', 'Basic'), ('pro', 'Pro'), ('premium', 'Premium')]
    STATUS_CHOICES = [('active', 'Active'), ('suspended', 'Suspended'), ('trial', 'Trial')]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    owner_name = models.CharField(max_length=255)
    phone = models.CharField(max_length=20)
    email = models.EmailField(max_length=255, null=True, blank=True)
    address = models.TextField(blank=True, default='')
    pan_number = models.CharField(max_length=20, null=True, blank=True)
    plan = models.CharField(max_length=10, choices=PLAN_CHOICES, default='basic')
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='trial')
    trial_ends_at = models.DateTimeField(null=True, blank=True)
    subscription_start = models.DateField(null=True, blank=True)
    subscription_expiry = models.DateField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = 'businesses'
        ordering = ['-created_at']

    def __str__(self):
        return self.name


class PlatformUser(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='platform_user')
    is_platform_admin = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Platform: {self.user.username}"


class ActivityLog(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    business = models.ForeignKey(Business, on_delete=models.CASCADE, null=True, blank=True, related_name='activity_logs')
    user_name = models.CharField(max_length=255, blank=True, default='')
    action = models.CharField(max_length=255)
    target = models.CharField(max_length=255)
    module = models.CharField(max_length=50)
    metadata = models.JSONField(null=True, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-timestamp']

    def __str__(self):
        return f"{self.action} - {self.target}"
