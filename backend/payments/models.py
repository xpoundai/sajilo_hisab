import uuid
from django.db import models
from core.models import Business
from accounts.models import BusinessUser
from transactions.models import Party, Bank, Wallet


class Payment(models.Model):
    TYPE_CHOICES = [('received', 'Received'), ('paid', 'Paid')]
    METHOD_CHOICES = [
        ('cash', 'Cash'), ('bank', 'Bank'),
        ('cheque', 'Cheque'), ('wallet', 'Wallet'),
    ]
    CATEGORY_CHOICES = [
        ('normal', 'Normal'), ('advance', 'Advance'),
        ('credit_settlement', 'Credit Settlement'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    business = models.ForeignKey(Business, on_delete=models.CASCADE, related_name='payments')
    party = models.ForeignKey(Party, on_delete=models.CASCADE, related_name='payments')
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    type = models.CharField(max_length=10, choices=TYPE_CHOICES)
    method = models.CharField(max_length=10, choices=METHOD_CHOICES, default='cash')
    bank = models.ForeignKey(Bank, on_delete=models.SET_NULL, null=True, blank=True)
    wallet = models.ForeignKey(Wallet, on_delete=models.SET_NULL, null=True, blank=True)
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES, default='normal')
    date = models.DateField()
    notes = models.TextField(blank=True, default='')
    created_by = models.ForeignKey(BusinessUser, on_delete=models.SET_NULL, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date', '-created_at']
        indexes = [
            models.Index(fields=['business', 'type']),
            models.Index(fields=['business', 'date']),
        ]

    def __str__(self):
        return f"{self.type}: {self.party.name} - NPR {self.amount}"


class CashBook(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    business = models.OneToOneField(Business, on_delete=models.CASCADE, related_name='cashbook')
    balance = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    last_adjusted_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"CashBook: {self.business.name} - NPR {self.balance}"


class CashAdjustment(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    business = models.ForeignKey(Business, on_delete=models.CASCADE, related_name='cash_adjustments')
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    reason = models.TextField()
    adjusted_by = models.ForeignKey(BusinessUser, on_delete=models.SET_NULL, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Adjustment: NPR {self.amount} - {self.reason[:50]}"
