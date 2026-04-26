import uuid
from django.db import models
from core.models import Business
from accounts.models import BusinessUser


class Party(models.Model):
    TYPE_CHOICES = [('customer', 'Customer'), ('vendor', 'Vendor')]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    business = models.ForeignKey(Business, on_delete=models.CASCADE, related_name='parties')
    name = models.CharField(max_length=255)
    type = models.CharField(max_length=10, choices=TYPE_CHOICES)
    phone = models.CharField(max_length=20, blank=True, default='')
    email = models.EmailField(max_length=255, null=True, blank=True)
    address = models.TextField(blank=True, default='')
    gstin = models.CharField(max_length=30, null=True, blank=True, verbose_name='PAN/VAT Number')
    credit_limit = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    balance = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    advance_balance = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    total_business = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']
        verbose_name_plural = 'parties'
        indexes = [
            models.Index(fields=['business', 'type']),
            models.Index(fields=['business', 'name']),
        ]

    def __str__(self):
        return f"{self.name} ({self.type})"


class Bank(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    business = models.ForeignKey(Business, on_delete=models.CASCADE, related_name='banks')
    name = models.CharField(max_length=255)
    account_number = models.CharField(max_length=50, blank=True, default='')
    balance = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return f"{self.name} - {self.account_number}"


class Wallet(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    business = models.ForeignKey(Business, on_delete=models.CASCADE, related_name='wallets')
    name = models.CharField(max_length=255)
    phone = models.CharField(max_length=20, blank=True, default='')
    balance = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    linked_bank = models.ForeignKey(Bank, on_delete=models.SET_NULL, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return f"{self.name} ({self.phone})"


class Transaction(models.Model):
    TYPE_CHOICES = [('sale', 'Sale'), ('purchase', 'Purchase')]
    PAYMENT_METHOD_CHOICES = [
        ('cash', 'Cash'), ('bank', 'Bank'),
        ('cheque', 'Cheque'), ('wallet', 'Wallet'),
    ]
    STATUS_CHOICES = [
        ('paid', 'Paid'), ('partial', 'Partial'),
        ('credit', 'Credit'), ('advance', 'Advance'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    business = models.ForeignKey(Business, on_delete=models.CASCADE, related_name='transactions')
    type = models.CharField(max_length=10, choices=TYPE_CHOICES)
    party = models.ForeignKey(Party, on_delete=models.CASCADE, related_name='transactions', null=True, blank=True)
    total = models.DecimalField(max_digits=12, decimal_places=2)
    paid = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    payment_method = models.CharField(max_length=10, choices=PAYMENT_METHOD_CHOICES, default='cash')
    bank = models.ForeignKey(Bank, on_delete=models.SET_NULL, null=True, blank=True)
    wallet = models.ForeignKey(Wallet, on_delete=models.SET_NULL, null=True, blank=True)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='credit')
    date = models.DateField()
    notes = models.TextField(blank=True, default='')
    created_by = models.ForeignKey(BusinessUser, on_delete=models.SET_NULL, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date', '-created_at']
        indexes = [
            models.Index(fields=['business', 'type']),
            models.Index(fields=['business', 'date']),
            models.Index(fields=['business', 'party']),
        ]

    def __str__(self):
        return f"{self.type}: {self.party.name} - NPR {self.total}"


class TransactionItem(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    transaction = models.ForeignKey(Transaction, on_delete=models.CASCADE, related_name='items')
    item = models.ForeignKey('inventory.Item', on_delete=models.SET_NULL, null=True)
    item_name = models.CharField(max_length=255)
    quantity = models.DecimalField(max_digits=12, decimal_places=2)
    rate = models.DecimalField(max_digits=12, decimal_places=2)
    total = models.DecimalField(max_digits=12, decimal_places=2)

    def __str__(self):
        return f"{self.item_name} x {self.quantity} @ {self.rate}"
