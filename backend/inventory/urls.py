from django.urls import path
from .views import ItemListCreateView, ItemDetailView, StockEntryListCreateView

urlpatterns = [
    path('items/', ItemListCreateView.as_view(), name='item-list-create'),
    path('items/<uuid:pk>/', ItemDetailView.as_view(), name='item-detail'),
    path('stock-entries/', StockEntryListCreateView.as_view(), name='stock-entry-list-create'),
]
