import uuid
from django.db import models
from core.models import Business
from accounts.models import BusinessUser


class Item(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    business = models.ForeignKey(Business, on_delete=models.CASCADE, related_name='items')
    name = models.CharField(max_length=255)
    unit = models.CharField(max_length=50, default='pcs')
    quantity = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    cost_price = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    selling_price = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    low_stock_threshold = models.IntegerField(default=20)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']
        indexes = [
            models.Index(fields=['business', 'name']),
        ]

    def __str__(self):
        return f"{self.name} ({self.quantity} {self.unit})"

    @property
    def is_low_stock(self):
        return self.quantity <= self.low_stock_threshold

    @property
    def stock_value(self):
        return self.quantity * self.cost_price


class StockEntry(models.Model):
    TYPE_CHOICES = [('in', 'Stock In'), ('out', 'Stock Out'), ('adjustment', 'Adjustment')]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    business = models.ForeignKey(Business, on_delete=models.CASCADE, related_name='stock_entries')
    item = models.ForeignKey(Item, on_delete=models.CASCADE, related_name='stock_entries')
    item_name = models.CharField(max_length=255)
    type = models.CharField(max_length=15, choices=TYPE_CHOICES)
    quantity = models.DecimalField(max_digits=12, decimal_places=2)
    rate = models.DecimalField(max_digits=12, decimal_places=2)
    total = models.DecimalField(max_digits=12, decimal_places=2)
    date = models.DateField()
    created_by = models.ForeignKey(BusinessUser, on_delete=models.SET_NULL, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date', '-created_at']
        verbose_name_plural = 'stock entries'

    def __str__(self):
        return f"{self.type}: {self.item_name} x {self.quantity}"
