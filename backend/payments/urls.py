from django.urls import path
from .views import PaymentListView, PaymentCreateView, CashBalanceView, CashAdjustView, FundTransferView

urlpatterns = [
    path('payments/', PaymentListView.as_view(), name='payment-list'),
    path('payments/create/', PaymentCreateView.as_view(), name='payment-create'),
    path('cash/balance/', CashBalanceView.as_view(), name='cash-balance'),
    path('cash/adjust/', CashAdjustView.as_view(), name='cash-adjust'),
    path('cash/transfer/', FundTransferView.as_view(), name='cash-transfer'),
]
