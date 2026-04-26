from django.urls import path
from .views import (
    LoginView, AdminLoginView, RegisterView, LogoutView,
    TokenRefreshView, ProfileView, UserListCreateView, UserDetailView,
)

urlpatterns = [
    path('login/', LoginView.as_view(), name='login'),
    path('login/admin/', AdminLoginView.as_view(), name='admin-login'),
    path('register/', RegisterView.as_view(), name='register'),
    path('logout/', LogoutView.as_view(), name='logout'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token-refresh'),
    path('profile/', ProfileView.as_view(), name='profile'),
    # User management (under /api/auth/ but logically user management)
    path('users/', UserListCreateView.as_view(), name='user-list-create'),
    path('users/<uuid:pk>/', UserDetailView.as_view(), name='user-detail'),
]
