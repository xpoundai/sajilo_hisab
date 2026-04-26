from django.urls import path
from .views import (
    PlatformStatsView, PlatformBusinessListView,
    PlatformBusinessDetailView, PlatformUserListView, SystemInfoView,
)

urlpatterns = [
    path('stats/', PlatformStatsView.as_view(), name='platform-stats'),
    path('businesses/', PlatformBusinessListView.as_view(), name='platform-businesses'),
    path('businesses/<uuid:pk>/', PlatformBusinessDetailView.as_view(), name='platform-business-detail'),
    path('users/', PlatformUserListView.as_view(), name='platform-users'),
    path('system-info/', SystemInfoView.as_view(), name='system-info'),
]
