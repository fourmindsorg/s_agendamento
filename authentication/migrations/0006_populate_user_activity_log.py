from django.conf import settings
from django.db import migrations


def create_activity_logs(apps, schema_editor):
    User = apps.get_model(settings.AUTH_USER_MODEL.split(".")[0], settings.AUTH_USER_MODEL.split(".")[1])
    UserActivityLog = apps.get_model("authentication", "UserActivityLog")

    for user in User.objects.all():
        UserActivityLog.objects.get_or_create(user=user)


def reverse_noop(apps, schema_editor):
    # Não remover registros existentes ao reverter
    pass


class Migration(migrations.Migration):

    dependencies = [
        ("authentication", "0005_useractivitylog"),
    ]

    operations = [
        migrations.RunPython(create_activity_logs, reverse_noop),
    ]

