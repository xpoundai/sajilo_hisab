from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import transaction as db_transaction

from .models import Item, StockEntry
from .serializers import ItemSerializer, ItemCreateSerializer, StockEntrySerializer, StockEntryCreateSerializer
from core.permissions import BusinessUserPermission, CanManageInventory
from core.mixins import BusinessScopedMixin
from core.models import ActivityLog


class ItemListCreateView(BusinessScopedMixin, generics.ListCreateAPIView):
    queryset = Item.objects.all()
    permission_classes = [IsAuthenticated, CanManageInventory]
    search_fields = ['name']
    filterset_fields = {'quantity': ['lte']}

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return ItemCreateSerializer
        return ItemSerializer

    def perform_create(self, serializer):
        item = serializer.save(business=self.get_business())
        ActivityLog.objects.create(
            business=self.get_business(),
            user_name=self.get_business_user().name,
            action='Item Created',
            target=item.name,
            module='inventory',
        )


class ItemDetailView(BusinessScopedMixin, generics.RetrieveUpdateDestroyAPIView):
    queryset = Item.objects.all()
    permission_classes = [IsAuthenticated, CanManageInventory]
    serializer_class = ItemSerializer

    def perform_update(self, serializer):
        item = serializer.save()
        ActivityLog.objects.create(
            business=self.get_business(),
            user_name=self.get_business_user().name,
            action='Item Updated',
            target=item.name,
            module='inventory',
        )


class StockEntryListCreateView(BusinessScopedMixin, generics.ListCreateAPIView):
    queryset = StockEntry.objects.all()
    permission_classes = [IsAuthenticated, CanManageInventory]
    filterset_fields = ['item', 'type']

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return StockEntryCreateSerializer
        return StockEntrySerializer

    @db_transaction.atomic
    def create(self, request, *args, **kwargs):
        serializer = StockEntryCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        business = self.get_business()
        try:
            item = Item.objects.get(id=data['item_id'], business=business)
        except Item.DoesNotExist:
            return Response({'error': 'Item not found.'}, status=status.HTTP_404_NOT_FOUND)

        quantity = data['quantity']
        rate = data['rate']
        total = quantity * rate

        if data['type'] == 'in':
            item.quantity += quantity
        elif data['type'] == 'out':
            if item.quantity < quantity:
                return Response({'error': 'Insufficient stock.'}, status=status.HTTP_400_BAD_REQUEST)
            item.quantity -= quantity
        else:  # adjustment
            item.quantity = quantity

        item.save()

        entry = StockEntry.objects.create(
            business=business,
            item=item,
            item_name=item.name,
            type=data['type'],
            quantity=quantity,
            rate=rate,
            total=total,
            date=data['date'],
            created_by=self.get_business_user(),
        )

        ActivityLog.objects.create(
            business=business,
            user_name=self.get_business_user().name,
            action=f'Stock {data["type"].title()}',
            target=item.name,
            module='inventory',
            metadata={'quantity': str(quantity), 'rate': str(rate)},
        )

        return Response(StockEntrySerializer(entry).data, status=status.HTTP_201_CREATED)
