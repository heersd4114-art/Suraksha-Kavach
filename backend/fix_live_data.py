
import os
import django
from django.conf import settings

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from fireguard_ai.models import UserProfile, Device, LiveData

print("Fixing Live Data...")

device = Device.objects.first()
if not device:
    print("No device found! Creating dummy device...")
    # Finding admin or first user
    user = UserProfile.objects.first()
    if not user:
         # Create a user if absolutely none exist (unlikely given check_db output)
         print("CRITICAL: No users found. Cannot proceed.")
         exit(1)
    
    device = Device.objects.create(
        device_id="SYS_MASTER_01",
        owner=user,
        building_id="FireGuard HQ",
        block="A",
        house="001",
        status="active"
    )
    print(f"Created Device: {device.device_id}")

# Check Live Data
defaults = {
    "gas": 50,
    "temp": 28,
    "flame": False,
    "sprinkler": False
}
live_data, created = LiveData.objects.get_or_create(device=device, defaults=defaults)

if created:
    print(f"Created LiveData entry for {device.device_id}")
else:
    print(f"LiveData already exists for {device.device_id}.")
    # Force update to trigger any listeners or just to be sure
    live_data.gas = 55
    live_data.temp = 29
    live_data.save()
    print("Updated LiveData values.")

print("Done.")
