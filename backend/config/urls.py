from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('accounts.urls')),
    path('api/', include('core.urls')),
    path('api/', include('inventory.urls')),
    path('api/', include('transactions.urls')),
    path('api/', include('payments.urls')),
    path('api/', include('reports.urls')),
    path('api/platform/', include('platform_admin.urls')),
]
