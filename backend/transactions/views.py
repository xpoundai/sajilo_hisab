from decimal import Decimal
from datetime import date

from rest_framework import generics, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import transaction as db_transaction
from django.db.models import Sum, Q

from .models import Party, Bank, Wallet, Transaction, TransactionItem
from .serializers import (
    PartySerializer, PartyCreateSerializer, BankSerializer, WalletSerializer,
    TransactionSerializer, TransactionCreateSerializer,
    PartyLedgerSerializer, DayBookSerializer,
)
from inventory.models import Item, StockEntry
from payments.models import Payment, CashBook
from core.permissions import (
    BusinessUserPermission, CanManageParties, CanCreateTransactions,
    CanManageBanks,
)
from core.mixins import BusinessScopedMixin
from core.models import ActivityLog


# ─── Party Views ──────────────────────────────────────────────
class PartyListCreateView(BusinessScopedMixin, generics.ListCreateAPIView):
    queryset = Party.objects.all()
    permission_classes = [IsAuthenticated, CanManageParties]
    search_fields = ['name', 'phone']
    filterset_fields = ['type']

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return PartyCreateSerializer
        return PartySerializer

    def perform_create(self, serializer):
        opening_balance = serializer.validated_data.pop('opening_balance', 0)
        opening_advance = serializer.validated_data.pop('opening_advance', 0)
        party = serializer.save(
            business=self.get_business(),
            balance=opening_balance,
            advance_balance=opening_advance,
        )
        ActivityLog.objects.create(
            business=self.get_business(),
            user_name=self.get_business_user().name,
            action='Party Created',
            target=party.name,
            module='parties',
        )


class PartyDetailView(BusinessScopedMixin, generics.RetrieveUpdateDestroyAPIView):
    queryset = Party.objects.all()
    permission_classes = [IsAuthenticated, CanManageParties]
    serializer_class = PartySerializer


class PartyLedgerView(BusinessScopedMixin, APIView):
    permission_classes = [IsAuthenticated, BusinessUserPermission]

    def get(self, request, pk):
        business = request.user.business_user.business
        try:
            party = Party.objects.get(id=pk, business=business)
        except Party.DoesNotExist:
            return Response({'error': 'Party not found.'}, status=status.HTTP_404_NOT_FOUND)

        # Get all transactions and payments for this party
        txns = Transaction.objects.filter(party=party).order_by('date', 'created_at')
        pmts = Payment.objects.filter(party=party).order_by('date', 'created_at')

        ledger = []
        for t in txns:
            if t.type == 'sale':
                ledger.append({
                    'date': t.date, 'type': 'Sale', 'description': f'Sale #{str(t.id)[:8]}',
                    'debit': t.total, 'credit': Decimal('0.00'),
                    'sort_key': (t.date, t.created_at),
                })
            else:
                ledger.append({
                    'date': t.date, 'type': 'Purchase', 'description': f'Purchase #{str(t.id)[:8]}',
                    'debit': Decimal('0.00'), 'credit': t.total,
                    'sort_key': (t.date, t.created_at),
                })

        for p in pmts:
            if p.type == 'received':
                ledger.append({
                    'date': p.date, 'type': 'Payment Received', 'description': f'Payment #{str(p.id)[:8]}',
                    'debit': Decimal('0.00'), 'credit': p.amount,
                    'sort_key': (p.date, p.created_at),
                })
            else:
                ledger.append({
                    'date': p.date, 'type': 'Payment Paid', 'description': f'Payment #{str(p.id)[:8]}',
                    'debit': p.amount, 'credit': Decimal('0.00'),
                    'sort_key': (p.date, p.created_at),
                })

        ledger.sort(key=lambda x: x['sort_key'])

        # Compute running balance
        running = Decimal('0.00')
        for entry in ledger:
            running += entry['debit'] - entry['credit']
            entry['balance'] = running
            del entry['sort_key']

        return Response({
            'party': PartySerializer(party).data,
            'ledger': ledger,
        })


# ─── Bank & Wallet Views ──────────────────────────────────────
class BankListCreateView(BusinessScopedMixin, generics.ListCreateAPIView):
    queryset = Bank.objects.all()
    permission_classes = [IsAuthenticated, CanManageBanks]
    serializer_class = BankSerializer

    def perform_create(self, serializer):
        serializer.save(business=self.get_business())


class BankDetailView(BusinessScopedMixin, generics.RetrieveUpdateDestroyAPIView):
    queryset = Bank.objects.all()
    permission_classes = [IsAuthenticated, CanManageBanks]
    serializer_class = BankSerializer

    @db_transaction.atomic
    def perform_destroy(self, instance):
        settle_to = self.request.query_params.get('settle_to', 'discard')
        if instance.balance > 0:
            if settle_to == 'cash':
                cashbook, _ = CashBook.objects.get_or_create(business=instance.business, defaults={'balance': 0})
                cashbook.balance += instance.balance
                cashbook.save()
        instance.delete()


class WalletListCreateView(BusinessScopedMixin, generics.ListCreateAPIView):
    queryset = Wallet.objects.all()
    permission_classes = [IsAuthenticated, CanManageBanks]
    serializer_class = WalletSerializer

    def perform_create(self, serializer):
        serializer.save(business=self.get_business())


class WalletDetailView(BusinessScopedMixin, generics.RetrieveUpdateDestroyAPIView):
    queryset = Wallet.objects.all()
    permission_classes = [IsAuthenticated, CanManageBanks]
    serializer_class = WalletSerializer

    @db_transaction.atomic
    def perform_destroy(self, instance):
        settle_to = self.request.query_params.get('settle_to', 'discard')
        if instance.balance > 0:
            if settle_to == 'cash':
                cashbook, _ = CashBook.objects.get_or_create(business=instance.business, defaults={'balance': 0})
                cashbook.balance += instance.balance
                cashbook.save()
            elif settle_to == 'linked_bank' and instance.linked_bank:
                instance.linked_bank.balance += instance.balance
                instance.linked_bank.save()
        instance.delete()


# ─── Transaction Views ────────────────────────────────────────
class TransactionListView(BusinessScopedMixin, generics.ListAPIView):
    queryset = Transaction.objects.all()
    serializer_class = TransactionSerializer
    permission_classes = [IsAuthenticated, BusinessUserPermission]
    search_fields = ['party__name']
    filterset_fields = ['type', 'status', 'payment_method']

    def get_queryset(self):
        qs = super().get_queryset()
        date_from = self.request.query_params.get('date_from')
        date_to = self.request.query_params.get('date_to')
        party_id = self.request.query_params.get('party')
        if date_from:
            qs = qs.filter(date__gte=date_from)
        if date_to:
            qs = qs.filter(date__lte=date_to)
        if party_id:
            qs = qs.filter(party_id=party_id)
        return qs


class TransactionDetailView(BusinessScopedMixin, generics.RetrieveAPIView):
    queryset = Transaction.objects.all()
    serializer_class = TransactionSerializer
    permission_classes = [IsAuthenticated, BusinessUserPermission]


class TransactionCreateView(APIView):
    permission_classes = [IsAuthenticated, CanCreateTransactions]

    @db_transaction.atomic
    def post(self, request):
        serializer = TransactionCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        business = request.user.business_user.business
        bu = request.user.business_user

        # Validate party
        party = None
        party_id = data.get('party_id')
        if party_id:
            try:
                party = Party.objects.get(id=party_id, business=business)
            except Party.DoesNotExist:
                return Response({'error': 'Party not found.'}, status=status.HTTP_404_NOT_FOUND)

        # Validate and process items
        total = Decimal('0.00')
        item_entries = []
        for item_data in data['items']:
            try:
                item = Item.objects.select_for_update().get(id=item_data['item_id'], business=business)
            except Item.DoesNotExist:
                return Response({'error': f'Item not found.'}, status=status.HTTP_404_NOT_FOUND)

            qty = item_data['quantity']
            rate = item_data['rate']
            line_total = qty * rate

            if data['type'] == 'sale' and item.quantity < qty:
                return Response(
                    {'error': f'Insufficient stock for {item.name}. Available: {item.quantity}'},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            item_entries.append({
                'item': item, 'quantity': qty, 'rate': rate, 'total': line_total,
            })
            total += line_total

        paid = data['paid']

        if not party and paid < total:
            return Response({'error': 'Cash sales without a party must be fully paid.'}, status=status.HTTP_400_BAD_REQUEST)

        # Determine status
        if paid >= total and paid > total:
            txn_status = 'advance'
        elif paid >= total:
            txn_status = 'paid'
        elif paid > 0:
            txn_status = 'partial'
        else:
            txn_status = 'credit'

        # Resolve bank/wallet
        bank = None
        wallet = None
        method = data['payment_method']

        if method in ['bank', 'cheque'] and data.get('bank_id'):
            try:
                bank = Bank.objects.select_for_update().get(id=data['bank_id'], business=business)
            except Bank.DoesNotExist:
                return Response({'error': 'Bank not found.'}, status=status.HTTP_404_NOT_FOUND)

        if method == 'wallet' and data.get('wallet_id'):
            try:
                wallet = Wallet.objects.select_for_update().get(id=data['wallet_id'], business=business)
            except Wallet.DoesNotExist:
                return Response({'error': 'Wallet not found.'}, status=status.HTTP_404_NOT_FOUND)

        # Create transaction
        txn = Transaction.objects.create(
            business=business, type=data['type'], party=party,
            total=total, paid=paid, payment_method=method,
            bank=bank, wallet=wallet, status=txn_status,
            date=data['date'], notes=data.get('notes', ''),
            created_by=bu,
        )

        # Create transaction items and update stock
        for entry in item_entries:
            item = entry['item']
            TransactionItem.objects.create(
                transaction=txn, item=item, item_name=item.name,
                quantity=entry['quantity'], rate=entry['rate'], total=entry['total'],
            )

            # Stock update
            if data['type'] == 'sale':
                item.quantity -= entry['quantity']
                stock_type = 'out'
            else:
                item.quantity += entry['quantity']
                stock_type = 'in'
            item.save()

            StockEntry.objects.create(
                business=business, item=item, item_name=item.name,
                type=stock_type, quantity=entry['quantity'],
                rate=entry['rate'], total=entry['total'],
                date=data['date'], created_by=bu,
            )

        # Update party balance
        if party:
            if data['type'] == 'sale':
                party.balance += (total - paid)
                if paid > total:
                    party.advance_balance += (paid - total)
            else:
                party.balance -= (total - paid)
                if paid > total:
                    party.advance_balance -= (paid - total)
            party.total_business += total
            party.save()

        # Payment routing
        if paid > 0:
            self._route_payment(business, method, paid, data['type'], bank, wallet)

        # Activity log
        ActivityLog.objects.create(
            business=business, user_name=bu.name,
            action=f'{data["type"].title()} Created',
            target=f'{party.name if party else "Cash Sale"} - NPR {total}',
            module='transactions',
            metadata={'transaction_id': str(txn.id), 'status': txn_status},
        )

        return Response(TransactionSerializer(txn).data, status=status.HTTP_201_CREATED)

    def _route_payment(self, business, method, amount, txn_type, bank, wallet):
        """Route payment to the correct source/destination."""
        cashbook, _ = CashBook.objects.get_or_create(business=business, defaults={'balance': 0})

        if txn_type == 'sale':
            # Money comes IN
            if method == 'cash':
                cashbook.balance += amount
                cashbook.save()
            elif method in ['bank', 'cheque'] and bank:
                bank.balance += amount
                bank.save()
            elif method == 'wallet' and wallet:
                wallet.balance += amount
                wallet.save()
        else:
            # Money goes OUT (purchase)
            if method == 'cash':
                cashbook.balance -= amount
                cashbook.save()
            elif method in ['bank', 'cheque'] and bank:
                bank.balance -= amount
                bank.save()
            elif method == 'wallet' and wallet:
                wallet.balance -= amount
                wallet.save()


# ─── Day Book View ─────────────────────────────────────────────
class DayBookView(BusinessScopedMixin, APIView):
    permission_classes = [IsAuthenticated, BusinessUserPermission]

    def get(self, request):
        business = request.user.business_user.business
        date_from = request.query_params.get('date_from', str(date.today()))
        date_to = request.query_params.get('date_to', str(date.today()))
        filter_type = request.query_params.get('type', 'all')

        entries = []

        # Get transactions
        txns = Transaction.objects.filter(
            business=business, date__gte=date_from, date__lte=date_to
        ).select_related('party')

        if filter_type in ['all', 'sale']:
            for t in txns.filter(type='sale'):
                entries.append({
                    'date': t.date, 'type': 'sale',
                    'description': f'Sale to {t.party.name if t.party else "Customer"}',
                    'party_name': t.party.name if t.party else 'Walk-in Customer',
                    'amount': t.total, 'method': t.payment_method,
                    'sort_key': t.created_at,
                })

        if filter_type in ['all', 'purchase']:
            for t in txns.filter(type='purchase'):
                entries.append({
                    'date': t.date, 'type': 'purchase',
                    'description': f'Purchase from {t.party.name if t.party else "Vendor"}',
                    'party_name': t.party.name if t.party else 'Vendor',
                    'amount': t.total, 'method': t.payment_method,
                    'sort_key': t.created_at,
                })

        # Get payments
        pmts = Payment.objects.filter(
            business=business, date__gte=date_from, date__lte=date_to
        ).select_related('party')

        if filter_type in ['all', 'payment_in']:
            for p in pmts.filter(type='received'):
                entries.append({
                    'date': p.date, 'type': 'payment_in',
                    'description': f'Payment from {p.party.name}',
                    'party_name': p.party.name,
                    'amount': p.amount, 'method': p.method,
                    'category': p.category,
                    'sort_key': p.created_at,
                })

        if filter_type in ['all', 'payment_out']:
            for p in pmts.filter(type='paid'):
                entries.append({
                    'date': p.date, 'type': 'payment_out',
                    'description': f'Payment to {p.party.name}',
                    'party_name': p.party.name,
                    'amount': p.amount, 'method': p.method,
                    'category': p.category,
                    'sort_key': p.created_at,
                })

        entries.sort(key=lambda x: x['sort_key'], reverse=True)
        for e in entries:
            del e['sort_key']

        # Summary stats
        today_sales = txns.filter(type='sale').aggregate(total=Sum('total'))['total'] or 0
        today_purchases = txns.filter(type='purchase').aggregate(total=Sum('total'))['total'] or 0

        # Total balances
        total_receivable = Party.objects.filter(
            business=business, type='customer', balance__gt=0
        ).aggregate(total=Sum('balance'))['total'] or 0

        total_payable = Party.objects.filter(
            business=business, type='vendor', balance__lt=0
        ).aggregate(total=Sum('balance'))['total'] or 0

        total_advance = Party.objects.filter(
            business=business, advance_balance__gt=0
        ).aggregate(total=Sum('advance_balance'))['total'] or 0

        cashbook = CashBook.objects.filter(business=business).first()
        cash_balance = cashbook.balance if cashbook else 0

        bank_total = Bank.objects.filter(business=business).aggregate(total=Sum('balance'))['total'] or 0
        wallet_total = Wallet.objects.filter(business=business).aggregate(total=Sum('balance'))['total'] or 0

        return Response({
            'entries': entries,
            'summary': {
                'today_sales': today_sales,
                'today_purchases': today_purchases,
                'total_receivable': total_receivable,
                'total_payable': abs(total_payable),
                'total_advance': total_advance,
                'cash_balance': cash_balance,
                'bank_balance': bank_total,
                'wallet_balance': wallet_total,
                'total_balance': cash_balance + bank_total + wallet_total,
                'bank_count': Bank.objects.filter(business=business).count(),
                'wallet_count': Wallet.objects.filter(business=business).count(),
                'party_count': Party.objects.filter(business=business).count(),
            },
        })
