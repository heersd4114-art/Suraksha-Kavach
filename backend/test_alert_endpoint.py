#!/usr/bin/env python
import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

import json
from django.test import Client
from fireguard_ai.models import UserProfile

# Create a test client
client = Client()

print("=" * 70)
print("TESTING EMERGENCY ALERT ENDPOINT")
print("=" * 70)

# Get any valid user
user = UserProfile.objects.first()
if not user:
    print("\n❌ No users found in database!")
    sys.exit(1)

print(f"\nUsing user: {user.name} (UID: {user.uid}, Role: {user.role})")

# Test data
payload = {
    'type': 'EMERGENCY',
    'severity': 'critical'
}

print(f"\n1. Testing POST request to /api/emergency-alert/")
print(f"   Payload: {json.dumps(payload, indent=2)}")
print(f"   Headers: X-User-ID: {user.uid}")

try:
    response = client.post(
        '/api/emergency-alert/',
        data=json.dumps(payload),
        content_type='application/json',
        HTTP_X_USER_ID=user.uid
    )
    
    print(f"\n2. Response Status: {response.status_code}")
    print(f"   Content-Type: {response.get('Content-Type')}")
    
    try:
        data = json.loads(response.content)
        print(f"   Response Body: {json.dumps(data, indent=2)}")
        if response.status_code == 200:
            print(f"\n✅ SUCCESS! Alert sent to {data.get('personnel_notified', 0)} personnel")
        else:
            print(f"\n❌ FAILED: {data.get('error', 'Unknown error')}")
    except:
        print(f"   Response Body: {response.content.decode()}")
        
except Exception as e:
    print(f"\n❌ ERROR: {e}")
    import traceback
    traceback.print_exc()

print("\n" + "=" * 70)
