from rest_framework import serializers
from .models import Payment, CashBook, CashAdjustment


class PaymentSerializer(serializers.ModelSerializer):
    party_name = serializers.CharField(source='party.name', read_only=True)
    created_by_name = serializers.CharField(source='created_by.name', read_only=True, default='')
    bank_name = serializers.CharField(source='bank.name', read_only=True, default='')
    wallet_name = serializers.CharField(source='wallet.name', read_only=True, default='')

    class Meta:
        model = Payment
        fields = [
            'id', 'party', 'party_name', 'amount', 'type', 'method',
            'bank', 'bank_name', 'wallet', 'wallet_name',
            'category', 'date', 'notes', 'created_by_name', 'created_at',
        ]
        read_only_fields = ['id', 'created_at']


class PaymentCreateSerializer(serializers.Serializer):
    party_id = serializers.UUIDField()
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    type = serializers.ChoiceField(choices=Payment.TYPE_CHOICES)
    method = serializers.ChoiceField(choices=Payment.METHOD_CHOICES, default='cash')
    bank_id = serializers.UUIDField(required=False, allow_null=True)
    wallet_id = serializers.UUIDField(required=False, allow_null=True)
    category = serializers.ChoiceField(choices=Payment.CATEGORY_CHOICES, default='normal')
    date = serializers.DateField()
    notes = serializers.CharField(required=False, allow_blank=True, default='')


class CashBookSerializer(serializers.ModelSerializer):
    class Meta:
        model = CashBook
        fields = ['id', 'balance', 'last_adjusted_at']


class CashAdjustmentSerializer(serializers.ModelSerializer):
    adjusted_by_name = serializers.CharField(source='adjusted_by.name', read_only=True, default='')

    class Meta:
        model = CashAdjustment
        fields = ['id', 'amount', 'reason', 'adjusted_by_name', 'created_at']
        read_only_fields = ['id', 'created_at']


class CashAdjustmentCreateSerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    reason = serializers.CharField()
