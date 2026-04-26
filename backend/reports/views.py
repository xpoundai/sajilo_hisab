from decimal import Decimal
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Sum, F, Q

from transactions.models import Transaction, TransactionItem, Party
from inventory.models import Item
from payments.models import Payment, CashBook
from transactions.models import Bank, Wallet
from core.permissions import CanViewReports, BusinessUserPermission
from core.models import ActivityLog


class SalesReportView(APIView):
    permission_classes = [IsAuthenticated, CanViewReports]

    def get(self, request):
        business = request.user.business_user.business
        date_from = request.query_params.get('date_from')
        date_to = request.query_params.get('date_to')
        party_id = request.query_params.get('party')

        qs = Transaction.objects.filter(business=business, type='sale')
        if date_from:
            qs = qs.filter(date__gte=date_from)
        if date_to:
            qs = qs.filter(date__lte=date_to)
        if party_id:
            qs = qs.filter(party_id=party_id)

        total_sales = qs.aggregate(total=Sum('total'))['total'] or 0
        total_paid = qs.aggregate(total=Sum('paid'))['total'] or 0
        count = qs.count()

        transactions = []
        for t in qs.select_related('party')[:100]:
            transactions.append({
                'id': str(t.id), 'date': t.date, 'party': t.party.name,
                'total': t.total, 'paid': t.paid, 'status': t.status,
                'method': t.payment_method,
            })

        return Response({
            'total_sales': total_sales,
            'total_collected': total_paid,
            'total_due': total_sales - total_paid,
            'count': count,
            'transactions': transactions,
        })


class PurchaseReportView(APIView):
    permission_classes = [IsAuthenticated, CanViewReports]

    def get(self, request):
        business = request.user.business_user.business
        date_from = request.query_params.get('date_from')
        date_to = request.query_params.get('date_to')
        party_id = request.query_params.get('party')

        qs = Transaction.objects.filter(business=business, type='purchase')
        if date_from:
            qs = qs.filter(date__gte=date_from)
        if date_to:
            qs = qs.filter(date__lte=date_to)
        if party_id:
            qs = qs.filter(party_id=party_id)

        total = qs.aggregate(total=Sum('total'))['total'] or 0
        total_paid = qs.aggregate(total=Sum('paid'))['total'] or 0
        count = qs.count()

        transactions = []
        for t in qs.select_related('party')[:100]:
            transactions.append({
                'id': str(t.id), 'date': t.date, 'party': t.party.name,
                'total': t.total, 'paid': t.paid, 'status': t.status,
                'method': t.payment_method,
            })

        return Response({
            'total_purchases': total,
            'total_paid': total_paid,
            'total_due': total - total_paid,
            'count': count,
            'transactions': transactions,
        })


class StockReportView(APIView):
    permission_classes = [IsAuthenticated, CanViewReports]

    def get(self, request):
        business = request.user.business_user.business
        items = Item.objects.filter(business=business)

        total_items = items.count()
        total_value = sum(i.quantity * i.cost_price for i in items)
        low_stock = items.filter(quantity__lte=F('low_stock_threshold')).count()

        item_list = []
        for i in items:
            item_list.append({
                'id': str(i.id), 'name': i.name, 'unit': i.unit,
                'quantity': i.quantity, 'cost_price': i.cost_price,
                'selling_price': i.selling_price,
                'stock_value': i.quantity * i.cost_price,
                'is_low_stock': i.quantity <= i.low_stock_threshold,
            })

        return Response({
            'total_items': total_items,
            'total_stock_value': total_value,
            'low_stock_count': low_stock,
            'items': item_list,
        })


class ProfitLossView(APIView):
    permission_classes = [IsAuthenticated, CanViewReports]

    def get(self, request):
        business = request.user.business_user.business
        date_from = request.query_params.get('date_from')
        date_to = request.query_params.get('date_to')

        sales_qs = Transaction.objects.filter(business=business, type='sale')
        purchase_qs = Transaction.objects.filter(business=business, type='purchase')

        if date_from:
            sales_qs = sales_qs.filter(date__gte=date_from)
            purchase_qs = purchase_qs.filter(date__gte=date_from)
        if date_to:
            sales_qs = sales_qs.filter(date__lte=date_to)
            purchase_qs = purchase_qs.filter(date__lte=date_to)

        total_sales = sales_qs.aggregate(total=Sum('total'))['total'] or Decimal('0')
        total_purchases = purchase_qs.aggregate(total=Sum('total'))['total'] or Decimal('0')
        gross_profit = total_sales - total_purchases

        return Response({
            'total_sales': total_sales,
            'total_purchases': total_purchases,
            'gross_profit': gross_profit,
            'profit_margin': round((gross_profit / total_sales * 100), 2) if total_sales > 0 else 0,
        })


class ReceivableReportView(APIView):
    permission_classes = [IsAuthenticated, CanViewReports]

    def get(self, request):
        business = request.user.business_user.business
        parties = Party.objects.filter(business=business, type='customer', balance__gt=0).order_by('-balance')

        total = parties.aggregate(total=Sum('balance'))['total'] or 0
        data = [{
            'id': str(p.id), 'name': p.name, 'phone': p.phone,
            'balance': p.balance, 'total_business': p.total_business,
        } for p in parties]

        return Response({'total_receivable': total, 'parties': data})


class PayableReportView(APIView):
    permission_classes = [IsAuthenticated, CanViewReports]

    def get(self, request):
        business = request.user.business_user.business
        parties = Party.objects.filter(business=business, type='vendor', balance__lt=0).order_by('balance')

        total = parties.aggregate(total=Sum('balance'))['total'] or 0
        data = [{
            'id': str(p.id), 'name': p.name, 'phone': p.phone,
            'balance': abs(p.balance), 'total_business': p.total_business,
        } for p in parties]

        return Response({'total_payable': abs(total), 'parties': data})


class CashFlowView(APIView):
    permission_classes = [IsAuthenticated, CanViewReports]

    def get(self, request):
        business = request.user.business_user.business
        date_from = request.query_params.get('date_from')
        date_to = request.query_params.get('date_to')

        sales_qs = Transaction.objects.filter(business=business, type='sale')
        purchase_qs = Transaction.objects.filter(business=business, type='purchase')
        received_qs = Payment.objects.filter(business=business, type='received')
        paid_qs = Payment.objects.filter(business=business, type='paid')

        if date_from:
            sales_qs = sales_qs.filter(date__gte=date_from)
            purchase_qs = purchase_qs.filter(date__gte=date_from)
            received_qs = received_qs.filter(date__gte=date_from)
            paid_qs = paid_qs.filter(date__gte=date_from)
        if date_to:
            sales_qs = sales_qs.filter(date__lte=date_to)
            purchase_qs = purchase_qs.filter(date__lte=date_to)
            received_qs = received_qs.filter(date__lte=date_to)
            paid_qs = paid_qs.filter(date__lte=date_to)

        cash_in = (sales_qs.aggregate(t=Sum('paid'))['t'] or 0) + (received_qs.aggregate(t=Sum('amount'))['t'] or 0)
        cash_out = (purchase_qs.aggregate(t=Sum('paid'))['t'] or 0) + (paid_qs.aggregate(t=Sum('amount'))['t'] or 0)

        cashbook = CashBook.objects.filter(business=business).first()

        return Response({
            'cash_in': cash_in,
            'cash_out': cash_out,
            'net_cash_flow': cash_in - cash_out,
            'current_cash_balance': cashbook.balance if cashbook else 0,
            'bank_balance': Bank.objects.filter(business=business).aggregate(t=Sum('balance'))['t'] or 0,
            'wallet_balance': Wallet.objects.filter(business=business).aggregate(t=Sum('balance'))['t'] or 0,
        })
