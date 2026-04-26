from rest_framework import serializers
from .models import Item, StockEntry


class ItemSerializer(serializers.ModelSerializer):
    is_low_stock = serializers.BooleanField(read_only=True)
    stock_value = serializers.DecimalField(max_digits=14, decimal_places=2, read_only=True)

    class Meta:
        model = Item
        fields = [
            'id', 'name', 'unit', 'quantity', 'cost_price', 'selling_price',
            'low_stock_threshold', 'is_low_stock', 'stock_value',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class ItemCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Item
        fields = ['name', 'unit', 'quantity', 'cost_price', 'selling_price', 'low_stock_threshold']


class StockEntrySerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.name', read_only=True, default='')

    class Meta:
        model = StockEntry
        fields = [
            'id', 'item', 'item_name', 'type', 'quantity', 'rate',
            'total', 'date', 'created_by_name', 'created_at',
        ]
        read_only_fields = ['id', 'item_name', 'total', 'created_at', 'created_by_name']


class StockEntryCreateSerializer(serializers.Serializer):
    item_id = serializers.UUIDField()
    type = serializers.ChoiceField(choices=StockEntry.TYPE_CHOICES)
    quantity = serializers.DecimalField(max_digits=12, decimal_places=2)
    rate = serializers.DecimalField(max_digits=12, decimal_places=2)
    date = serializers.DateField()
