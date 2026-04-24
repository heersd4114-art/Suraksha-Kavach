
import os
import django
from django.conf import settings

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from fireguard_ai.models import UserProfile, Device, LiveData

print("--- USERS ---")
for u in UserProfile.objects.all():
    print(f"UID: {u.uid}, Role: {u.role}, Name: {u.name}")

print("\n--- DEVICES ---")
for d in Device.objects.all():
    print(f"ID: {d.device_id}, Owner: {d.owner.uid if d.owner else 'None'}, Status: {d.status}")

print("\n--- LIVE DATA ---")
for l in LiveData.objects.all():
    print(f"Device: {l.device.device_id}, Gas: {l.gas}, Temp: {l.temp}, Sprinkler: {l.sprinkler}, Time: {l.updated_at}")
