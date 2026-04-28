"""
Django signals that automatically create Notification records when key
business events occur (transactions, payments, low-stock, new users).
"""
from django.db.models.signals import post_save
from django.dispatch import receiver

from .models import Notification


# ─── Helper ──────────────────────────────────────────────────────────────────

def _create(business, title, message, notif_type, priority='medium', data=None, recipient=None):
    """Convenience wrapper to create a Notification."""
    Notification.objects.create(
        business=business,
        recipient=recipient,
        type=notif_type,
        priority=priority,
        title=title,
        message=message,
        data=data or {},
    )


# ─── Transaction signals ─────────────────────────────────────────────────────

@receiver(post_save, sender='transactions.Transaction')
def on_transaction_created(sender, instance, created, **kwargs):
    if not created:
        return

    txn_type = 'Sale' if instance.type == 'sale' else 'Purchase'
    party_name = instance.party.name if instance.party else 'Unknown'
    amount = f"NPR {instance.total:,.2f}"

    if instance.status == 'credit':
        priority = 'high'
        extra = f" (Credit – NPR {instance.total - instance.paid:,.2f} due)"
    elif instance.status == 'partial':
        priority = 'medium'
        extra = f" (Partial – NPR {instance.total - instance.paid:,.2f} remaining)"
    else:
        priority = 'low'
        extra = ''

    _create(
        business=instance.business,
        title=f"New {txn_type} – {party_name}",
        message=f"{txn_type} of {amount} recorded for {party_name}{extra}.",
        notif_type='transaction',
        priority=priority,
        data={'module': 'transactions', 'id': str(instance.id), 'type': instance.type},
    )


# ─── Payment signals ─────────────────────────────────────────────────────────

@receiver(post_save, sender='payments.Payment')
def on_payment_created(sender, instance, created, **kwargs):
    if not created:
        return

    direction = 'Received' if instance.type == 'received' else 'Paid'
    party_name = instance.party.name
    amount = f"NPR {instance.amount:,.2f}"

    _create(
        business=instance.business,
        title=f"Payment {direction} – {party_name}",
        message=f"{amount} {direction.lower()} via {instance.method.title()} for {party_name}.",
        notif_type='payment',
        priority='medium',
        data={'module': 'payments', 'id': str(instance.id), 'type': instance.type},
    )


# ─── Inventory / low-stock signals ───────────────────────────────────────────

@receiver(post_save, sender='inventory.Item')
def on_item_low_stock(sender, instance, created, **kwargs):
    """Fire a high-priority notification when an item hits low-stock threshold."""
    if created:
        return  # skip on initial creation

    if instance.is_low_stock:
        # Avoid duplicate notifications: only create if no unread low-stock
        # notification for this item already exists.
        already_notified = Notification.objects.filter(
            business=instance.business,
            type='inventory',
            is_read=False,
            data__id=str(instance.id),
        ).exists()

        if not already_notified:
            _create(
                business=instance.business,
                title=f"Low Stock Alert – {instance.name}",
                message=(
                    f"{instance.name} is running low: only "
                    f"{instance.quantity} {instance.unit} remaining "
                    f"(threshold: {instance.low_stock_threshold})."
                ),
                notif_type='inventory',
                priority='high',
                data={'module': 'inventory', 'id': str(instance.id), 'item_name': instance.name},
            )


# ─── New business user signals ────────────────────────────────────────────────

@receiver(post_save, sender='accounts.BusinessUser')
def on_business_user_created(sender, instance, created, **kwargs):
    if not created:
        return

    _create(
        business=instance.business,
        title="New Team Member Added",
        message=f"{instance.name} has been added as {instance.role.title()} to your business.",
        notif_type='user',
        priority='low',
        data={'module': 'users', 'id': str(instance.id), 'role': instance.role},
    )
