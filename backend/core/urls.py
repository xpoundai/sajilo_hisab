from django.urls import path
from .views import (
    BusinessDetailView,
    NotificationListView,
    NotificationMarkReadView,
    NotificationMarkAllReadView,
    NotificationDeleteView,
    NotificationUnreadCountView,
)

urlpatterns = [
    path('business/', BusinessDetailView.as_view(), name='business-detail'),

    # Notifications
    path('notifications/', NotificationListView.as_view(), name='notification-list'),
    path('notifications/unread-count/', NotificationUnreadCountView.as_view(), name='notification-unread-count'),
    path('notifications/mark-all-read/', NotificationMarkAllReadView.as_view(), name='notification-mark-all-read'),
    path('notifications/<uuid:pk>/read/', NotificationMarkReadView.as_view(), name='notification-mark-read'),
    path('notifications/<uuid:pk>/', NotificationDeleteView.as_view(), name='notification-delete'),
]
