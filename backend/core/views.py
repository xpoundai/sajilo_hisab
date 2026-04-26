from rest_framework import generics
from rest_framework.permissions import IsAuthenticated
from core.permissions import BusinessUserPermission, IsBusinessAdmin
from core.mixins import BusinessScopedMixin
from .models import Business
from .serializers import BusinessSerializer, BusinessUpdateSerializer


class BusinessDetailView(generics.RetrieveUpdateAPIView):
    permission_classes = [IsAuthenticated, BusinessUserPermission]
    serializer_class = BusinessSerializer

    def get_object(self):
        return self.request.user.business_user.business

    def get_serializer_class(self):
        if self.request.method in ['PATCH', 'PUT']:
            if self.request.user.business_user.role != 'admin':
                from rest_framework.exceptions import PermissionDenied
                raise PermissionDenied("Only admins can update business info.")
            return BusinessUpdateSerializer
        return BusinessSerializer
