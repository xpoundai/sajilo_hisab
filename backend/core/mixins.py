class BusinessScopedMixin:
    """Mixin that filters querysets by the current user's business."""
    def get_queryset(self):
        qs = super().get_queryset()
        if hasattr(self.request.user, 'business_user'):
            return qs.filter(business=self.request.user.business_user.business)
        return qs.none()

    def get_business(self):
        return self.request.user.business_user.business

    def get_business_user(self):
        return self.request.user.business_user
