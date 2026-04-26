from rest_framework.permissions import BasePermission


class IsBusinessAdmin(BasePermission):
    def has_permission(self, request, view):
        if not hasattr(request.user, 'business_user'):
            return False
        return request.user.business_user.role == 'admin'


class IsBusinessManager(BasePermission):
    def has_permission(self, request, view):
        if not hasattr(request.user, 'business_user'):
            return False
        return request.user.business_user.role in ['admin', 'manager']


class IsPlatformAdmin(BasePermission):
    def has_permission(self, request, view):
        return hasattr(request.user, 'platform_user') and request.user.platform_user.is_platform_admin


class HasPermission:
    """Factory for permission classes checking specific permission strings."""
    def __init__(self, perm):
        self.perm = perm

    def __call__(self):
        perm = self.perm
        class PermClass(BasePermission):
            def has_permission(self, request, view):
                if not hasattr(request.user, 'business_user'):
                    return False
                return request.user.business_user.has_permission(perm)
        PermClass.__name__ = f'Has_{perm}'
        return PermClass


class BusinessUserPermission(BasePermission):
    """Base permission - ensures user is a valid business user."""
    def has_permission(self, request, view):
        return hasattr(request.user, 'business_user') and request.user.business_user.is_active


class CanCreateTransactions(BasePermission):
    def has_permission(self, request, view):
        if not hasattr(request.user, 'business_user'):
            return False
        return request.user.business_user.has_permission('create_transactions')


class CanManageInventory(BasePermission):
    def has_permission(self, request, view):
        if not hasattr(request.user, 'business_user'):
            return False
        bu = request.user.business_user
        if request.method in ['GET', 'HEAD', 'OPTIONS']:
            return bu.has_permission('view_inventory')
        return bu.has_permission('manage_inventory')


class CanManageParties(BasePermission):
    def has_permission(self, request, view):
        if not hasattr(request.user, 'business_user'):
            return False
        bu = request.user.business_user
        if request.method in ['GET', 'HEAD', 'OPTIONS']:
            return bu.has_permission('view_parties')
        return bu.has_permission('manage_parties')


class CanManagePayments(BasePermission):
    def has_permission(self, request, view):
        if not hasattr(request.user, 'business_user'):
            return False
        bu = request.user.business_user
        if request.method in ['GET', 'HEAD', 'OPTIONS']:
            return bu.has_permission('view_payments')
        return bu.has_permission('manage_payments')


class CanViewReports(BasePermission):
    def has_permission(self, request, view):
        if not hasattr(request.user, 'business_user'):
            return False
        return request.user.business_user.has_permission('view_reports')


class CanManageUsers(BasePermission):
    def has_permission(self, request, view):
        if not hasattr(request.user, 'business_user'):
            return False
        return request.user.business_user.has_permission('manage_users')


class CanManageBanks(BasePermission):
    def has_permission(self, request, view):
        if not hasattr(request.user, 'business_user'):
            return False
        bu = request.user.business_user
        if request.method in ['GET', 'HEAD', 'OPTIONS']:
            return bu.has_permission('view_dashboard')
        return bu.has_permission('manage_banks')
