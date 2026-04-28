from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import Q
from core.permissions import BusinessUserPermission, IsBusinessAdmin
from core.mixins import BusinessScopedMixin
from .models import Business, Notification
from .serializers import BusinessSerializer, BusinessUpdateSerializer, NotificationSerializer


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


class NotificationListView(APIView):
    """
    GET  /api/notifications/        - list notifications for the current user
    Query params:
      ?unread=true   - only unread
      ?type=payment  - filter by type
    """
    permission_classes = [IsAuthenticated, BusinessUserPermission]

    def get(self, request):
        business = request.user.business_user.business
        # Show notifications addressed to this user OR broadcast to the whole business
        qs = Notification.objects.filter(
            business=business
        ).filter(
            Q(recipient=request.user) | Q(recipient__isnull=True)
        )

        unread_only = request.query_params.get('unread', '').lower() == 'true'
        if unread_only:
            qs = qs.filter(is_read=False)

        notif_type = request.query_params.get('type')
        if notif_type:
            qs = qs.filter(type=notif_type)

        serializer = NotificationSerializer(qs[:100], many=True)
        unread_count = Notification.objects.filter(
            business=business, is_read=False
        ).filter(
            Q(recipient=request.user) | Q(recipient__isnull=True)
        ).count()

        return Response({
            'results': serializer.data,
            'unread_count': unread_count,
        })


class NotificationMarkReadView(APIView):
    """
    PATCH /api/notifications/<id>/read/   - mark single notification as read
    POST  /api/notifications/mark-all-read/ - mark all as read
    """
    permission_classes = [IsAuthenticated, BusinessUserPermission]

    def patch(self, request, pk):
        business = request.user.business_user.business
        try:
            notif = Notification.objects.get(
                id=pk, business=business
            )
        except Notification.DoesNotExist:
            return Response({'error': 'Notification not found.'}, status=status.HTTP_404_NOT_FOUND)

        notif.is_read = True
        notif.save(update_fields=['is_read'])
        return Response({'status': 'marked as read'})


class NotificationMarkAllReadView(APIView):
    """POST /api/notifications/mark-all-read/"""
    permission_classes = [IsAuthenticated, BusinessUserPermission]

    def post(self, request):
        business = request.user.business_user.business
        updated = Notification.objects.filter(
            business=business, is_read=False
        ).filter(
            Q(recipient=request.user) | Q(recipient__isnull=True)
        ).update(is_read=True)
        return Response({'marked_read': updated})


class NotificationDeleteView(APIView):
    """DELETE /api/notifications/<id>/"""
    permission_classes = [IsAuthenticated, BusinessUserPermission]

    def delete(self, request, pk):
        business = request.user.business_user.business
        try:
            notif = Notification.objects.get(id=pk, business=business)
        except Notification.DoesNotExist:
            return Response({'error': 'Notification not found.'}, status=status.HTTP_404_NOT_FOUND)
        notif.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class NotificationUnreadCountView(APIView):
    """GET /api/notifications/unread-count/"""
    permission_classes = [IsAuthenticated, BusinessUserPermission]

    def get(self, request):
        business = request.user.business_user.business
        count = Notification.objects.filter(
            business=business, is_read=False
        ).filter(
            Q(recipient=request.user) | Q(recipient__isnull=True)
        ).count()
        return Response({'unread_count': count})
