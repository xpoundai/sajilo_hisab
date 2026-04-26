from decimal import Decimal
from rest_framework import generics, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import transaction as db_transaction

from .models import Payment, CashBook, CashAdjustment
from .serializers import (
    PaymentSerializer, PaymentCreateSerializer,
    CashBookSerializer, CashAdjustmentSerializer, CashAdjustmentCreateSerializer,
)
from transactions.models import Party, Bank, Wallet
from core.permissions import BusinessUserPermission, CanManagePayments, IsBusinessAdmin
from core.mixins import BusinessScopedMixin
from core.models import ActivityLog


class PaymentListView(BusinessScopedMixin, generics.ListAPIView):
    queryset = Payment.objects.all()
    serializer_class = PaymentSerializer
    permission_classes = [IsAuthenticated, CanManagePayments]
    search_fields = ['party__name']
    filterset_fields = ['type', 'method', 'category']


class PaymentCreateView(APIView):
    permission_classes = [IsAuthenticated, CanManagePayments]

    @db_transaction.atomic
    def post(self, request):
        serializer = PaymentCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        business = request.user.business_user.business
        bu = request.user.business_user

        # Validate party
        try:
            party = Party.objects.select_for_update().get(id=data['party_id'], business=business)
        except Party.DoesNotExist:
            return Response({'error': 'Party not found.'}, status=status.HTTP_404_NOT_FOUND)

        amount = data['amount']
        method = data['method']
        category = data['category']

        # Resolve bank/wallet
        bank = None
        wallet = None

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

        # Create payment
        payment = Payment.objects.create(
            business=business, party=party, amount=amount,
            type=data['type'], method=method,
            bank=bank, wallet=wallet,
            category=category, date=data['date'],
            notes=data.get('notes', ''), created_by=bu,
        )

        # Update party balance
        cashbook, _ = CashBook.objects.get_or_create(business=business, defaults={'balance': 0})

        if data['type'] == 'received':
            # Money coming in
            if category == 'advance':
                party.advance_balance += amount
            else:
                party.balance -= amount  # Reduce receivable
            # Route money in
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
            # Money going out
            if category == 'advance':
                party.advance_balance -= amount
            else:
                party.balance += amount  # Reduce payable (towards 0)
            # Route money out
            if method == 'cash':
                cashbook.balance -= amount
                cashbook.save()
            elif method in ['bank', 'cheque'] and bank:
                bank.balance -= amount
                bank.save()
            elif method == 'wallet' and wallet:
                wallet.balance -= amount
                wallet.save()

        party.save()

        ActivityLog.objects.create(
            business=business, user_name=bu.name,
            action=f'Payment {data["type"].title()}',
            target=f'{party.name} - NPR {amount}',
            module='payments',
            metadata={'payment_id': str(payment.id), 'method': method, 'category': category},
        )

        return Response(PaymentSerializer(payment).data, status=status.HTTP_201_CREATED)


class CashBalanceView(APIView):
    permission_classes = [IsAuthenticated, BusinessUserPermission]

    def get(self, request):
        business = request.user.business_user.business
        cashbook, _ = CashBook.objects.get_or_create(business=business, defaults={'balance': 0})
        return Response(CashBookSerializer(cashbook).data)


class CashAdjustView(APIView):
    permission_classes = [IsAuthenticated, IsBusinessAdmin]

    @db_transaction.atomic
    def post(self, request):
        serializer = CashAdjustmentCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        business = request.user.business_user.business
        bu = request.user.business_user

        cashbook, _ = CashBook.objects.get_or_create(business=business, defaults={'balance': 0})
        cashbook.balance += data['amount']
        cashbook.save()

        adjustment = CashAdjustment.objects.create(
            business=business, amount=data['amount'],
            reason=data['reason'], adjusted_by=bu,
        )

        ActivityLog.objects.create(
            business=business, user_name=bu.name,
            action='Cash Adjusted',
            target=f'NPR {data["amount"]}',
            module='system',
        )

        return Response(CashAdjustmentSerializer(adjustment).data, status=status.HTTP_201_CREATED)


class FundTransferView(APIView):
    permission_classes = [IsAuthenticated, CanManagePayments]

    @db_transaction.atomic
    def post(self, request):
        business = request.user.business_user.business
        bu = request.user.business_user

        source = request.data.get('source')
        destination = request.data.get('destination')
        try:
            amount = Decimal(str(request.data.get('amount', '0')))
        except Exception:
            return Response({'error': 'Invalid amount.'}, status=400)

        if amount <= 0:
            return Response({'error': 'Amount must be greater than zero.'}, status=400)
        if not source or not destination or source == destination:
            return Response({'error': 'Valid and distinct source and destination are required.'}, status=400)

        def get_account_and_balance(identifier):
            if identifier == 'cash':
                cashbook, _ = CashBook.objects.get_or_create(business=business, defaults={'balance': 0})
                return cashbook, cashbook.balance
            elif identifier.startswith('bank_'):
                bank = Bank.objects.select_for_update().get(id=identifier.split('_')[1], business=business)
                return bank, bank.balance
            elif identifier.startswith('wallet_'):
                wallet = Wallet.objects.select_for_update().get(id=identifier.split('_')[1], business=business)
                return wallet, wallet.balance
            else:
                raise Exception("Unknown identifier")

        try:
            src_acc, src_bal = get_account_and_balance(source)
            dest_acc, dest_bal = get_account_and_balance(destination)
        except Exception as e:
            return Response({'error': 'Account not found or invalid.'}, status=404)

        if src_bal < amount:
            return Response({'error': 'Insufficient funds in source account.'}, status=400)

        src_acc.balance -= amount
        dest_acc.balance += amount
        src_acc.save()
        dest_acc.save()

        notes = request.data.get('notes', '')
        ActivityLog.objects.create(
            business=business, user_name=bu.name,
            action='Fund Transfer',
            target=f'NPR {amount} from {source} to {destination}',
            module='payments',
            metadata={'source': source, 'destination': destination, 'notes': notes}
        )

        return Response({'message': 'Transfer successful'})
