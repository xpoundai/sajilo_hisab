from django.urls import path
from .views import (
    SalesReportView, PurchaseReportView, StockReportView,
    ProfitLossView, ReceivableReportView, PayableReportView, CashFlowView,
)

urlpatterns = [
    path('reports/sales/', SalesReportView.as_view(), name='report-sales'),
    path('reports/purchases/', PurchaseReportView.as_view(), name='report-purchases'),
    path('reports/stock/', StockReportView.as_view(), name='report-stock'),
    path('reports/profit-loss/', ProfitLossView.as_view(), name='report-profit-loss'),
    path('reports/receivable/', ReceivableReportView.as_view(), name='report-receivable'),
    path('reports/payable/', PayableReportView.as_view(), name='report-payable'),
    path('reports/cashflow/', CashFlowView.as_view(), name='report-cashflow'),
]
