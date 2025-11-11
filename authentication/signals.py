from __future__ import annotations

from django.contrib.auth import get_user_model
from django.contrib.auth.signals import (
    user_logged_in,
    user_logged_out,
    user_login_failed,
)
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.utils import timezone

from .models import UserActivityLog
from .utils import get_client_ip, get_user_agent


@receiver(post_save, sender=get_user_model())
def ensure_activity_log_exists(sender, instance, created, **kwargs):
    """Garante que todo usuário tenha um registro de atividade."""
    if created:
        UserActivityLog.objects.get_or_create(user=instance)


@receiver(user_logged_in)
def handle_user_logged_in(sender, request, user, **kwargs):
    if not user or not user.is_authenticated:
        return

    activity, _ = UserActivityLog.objects.get_or_create(user=user)
    activity.increment_login_success(
        ip=get_client_ip(request), user_agent=get_user_agent(request)
    )


@receiver(user_logged_out)
def handle_user_logged_out(sender, request, user, **kwargs):
    if not user or not user.is_authenticated:
        return

    activity, _ = UserActivityLog.objects.get_or_create(user=user)
    now = timezone.now()
    updates = {
        "last_activity": now,
        "last_request_path": "logout",
        "last_user_agent": get_user_agent(request),
        "updated_at": now,
    }
    UserActivityLog.objects.filter(pk=activity.pk).update(**updates)
    activity.refresh_from_db(fields=list(updates.keys()))


@receiver(user_login_failed)
def handle_user_login_failed(sender, credentials, request, **kwargs):
    username = credentials.get("username")
    if not username:
        return

    User = get_user_model()
    try:
        user = User.objects.get(username=username)
    except User.DoesNotExist:
        return

    activity, _ = UserActivityLog.objects.get_or_create(user=user)
    activity.increment_login_failed()

