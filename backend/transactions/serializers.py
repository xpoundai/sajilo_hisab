from rest_framework import serializers
from .models import Party, Bank, Wallet, Transaction, TransactionItem


class PartySerializer(serializers.ModelSerializer):
    class Meta:
        model = Party
        fields = [
            'id', 'name', 'type', 'phone', 'email', 'address', 'gstin',
            'credit_limit', 'balance', 'advance_balance', 'total_business',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'balance', 'advance_balance', 'total_business', 'created_at', 'updated_at']


class PartyCreateSerializer(serializers.ModelSerializer):
    opening_balance = serializers.DecimalField(max_digits=12, decimal_places=2, default=0, required=False)
    opening_advance = serializers.DecimalField(max_digits=12, decimal_places=2, default=0, required=False)

    class Meta:
        model = Party
        fields = ['name', 'type', 'phone', 'email', 'address', 'gstin', 'credit_limit', 'opening_balance', 'opening_advance']


class BankSerializer(serializers.ModelSerializer):
    class Meta:
        model = Bank
        fields = ['id', 'name', 'account_number', 'balance', 'created_at']
        read_only_fields = ['id', 'created_at']


class WalletSerializer(serializers.ModelSerializer):
    linked_bank_name = serializers.CharField(source='linked_bank.name', read_only=True, default='')

    class Meta:
        model = Wallet
        fields = ['id', 'name', 'phone', 'balance', 'linked_bank', 'linked_bank_name', 'created_at']
        read_only_fields = ['id', 'created_at']


class TransactionItemSerializer(serializers.Serializer):
    item_id = serializers.UUIDField()
    quantity = serializers.DecimalField(max_digits=12, decimal_places=2)
    rate = serializers.DecimalField(max_digits=12, decimal_places=2)


class TransactionSerializer(serializers.ModelSerializer):
    items = serializers.SerializerMethodField()
    party_name = serializers.SerializerMethodField()
    created_by_name = serializers.CharField(source='created_by.name', read_only=True, default='')

    class Meta:
        model = Transaction
        fields = [
            'id', 'type', 'party', 'party_name', 'total', 'paid',
            'payment_method', 'bank', 'wallet', 'status', 'date',
            'notes', 'created_by_name', 'created_at', 'items',
        ]
        read_only_fields = ['id', 'status', 'created_at']

    def get_items(self, obj):
        return TransactionItemReadSerializer(obj.items.all(), many=True).data

    def get_party_name(self, obj):
        return obj.party.name if obj.party else 'Cash Sale'


class TransactionItemReadSerializer(serializers.ModelSerializer):
    class Meta:
        model = TransactionItem
        fields = ['id', 'item', 'item_name', 'quantity', 'rate', 'total']


class TransactionCreateSerializer(serializers.Serializer):
    type = serializers.ChoiceField(choices=Transaction.TYPE_CHOICES)
    party_id = serializers.UUIDField(required=False, allow_null=True)
    items = TransactionItemSerializer(many=True)
    paid = serializers.DecimalField(max_digits=12, decimal_places=2, default=0)
    payment_method = serializers.ChoiceField(choices=Transaction.PAYMENT_METHOD_CHOICES, default='cash')
    bank_id = serializers.UUIDField(required=False, allow_null=True)
    wallet_id = serializers.UUIDField(required=False, allow_null=True)
    date = serializers.DateField()
    notes = serializers.CharField(required=False, allow_blank=True, default='')

    def validate_items(self, value):
        if not value:
            raise serializers.ValidationError('At least one item is required.')
        return value


class PartyLedgerSerializer(serializers.Serializer):
    date = serializers.DateField()
    type = serializers.CharField()
    description = serializers.CharField()
    debit = serializers.DecimalField(max_digits=12, decimal_places=2)
    credit = serializers.DecimalField(max_digits=12, decimal_places=2)
    balance = serializers.DecimalField(max_digits=12, decimal_places=2)


class DayBookSerializer(serializers.Serializer):
    date = serializers.DateField()
    type = serializers.CharField()
    description = serializers.CharField()
    party_name = serializers.CharField()
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    method = serializers.CharField()
    category = serializers.CharField(required=False, default='')
