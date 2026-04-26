from django.urls import path
from .views import (
    PartyListCreateView, PartyDetailView, PartyLedgerView,
    BankListCreateView, BankDetailView,
    WalletListCreateView, WalletDetailView,
    TransactionListView, TransactionDetailView, TransactionCreateView,
    DayBookView,
)

urlpatterns = [
    path('parties/', PartyListCreateView.as_view(), name='party-list-create'),
    path('parties/<uuid:pk>/', PartyDetailView.as_view(), name='party-detail'),
    path('parties/<uuid:pk>/ledger/', PartyLedgerView.as_view(), name='party-ledger'),
    path('banks/', BankListCreateView.as_view(), name='bank-list-create'),
    path('banks/<uuid:pk>/', BankDetailView.as_view(), name='bank-detail'),
    path('wallets/', WalletListCreateView.as_view(), name='wallet-list-create'),
    path('wallets/<uuid:pk>/', WalletDetailView.as_view(), name='wallet-detail'),
    path('transactions/', TransactionListView.as_view(), name='transaction-list'),
    path('transactions/create/', TransactionCreateView.as_view(), name='transaction-create'),
    path('transactions/<uuid:pk>/', TransactionDetailView.as_view(), name='transaction-detail'),
    path('daybook/', DayBookView.as_view(), name='daybook'),
]
