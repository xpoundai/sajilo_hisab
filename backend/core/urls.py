from django.urls import path
from .views import BusinessDetailView

urlpatterns = [
    path('business/', BusinessDetailView.as_view(), name='business-detail'),
]
