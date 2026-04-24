#!/usr/bin/env python
import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from fireguard_ai.models import UserProfile, Alert, Incident, AuditLog

print("=" * 70)
print("ALERT SYSTEM DEBUG")
print("=" * 70)

# Check 1: Users in database
print("\n1. CHECKING USERS IN DATABASE:")
users = UserProfile.objects.all()
print(f"   Total users: {users.count()}")
if users.count() == 0:
    print("   ❌ NO USERS FOUND - This is why alerts won't send!")
    print("   Add users via Django admin or mobile app")
else:
    for user in users:
        token_status = "✅ Has FCM Token" if user.fcm_token else "❌ NO FCM Token"
        print(f"   • {user.name} ({user.role}) - {token_status}")

# Check 2: Firebase configuration
print("\n2. CHECKING FIREBASE CONFIGURATION:")
try:
    from firebase_admin import credentials
    import firebase_admin
    
    if firebase_admin._apps:
        print("   ✅ Firebase initialized")
    else:
        print("   ❌ Firebase NOT initialized")
        
    # Check firebase_key.json
    import os
    key_path = os.path.join(os.path.dirname(__file__), 'firebase_key.json')
    if os.path.exists(key_path):
        print("   ✅ firebase_key.json found")
    else:
        print("   ❌ firebase_key.json NOT found")
        
except Exception as e:
    print(f"   ❌ Firebase error: {e}")

# Check 3: Existing alerts
print("\n3. CHECKING EXISTING ALERTS:")
alerts = Alert.objects.all().order_by('-time')[:5]
if alerts.count() == 0:
    print("   No alerts created yet")
else:
    for alert in alerts:
        print(f"   • {alert.alert_id} - {alert.incident.incident_type} ({alert.status}) at {alert.time}")

# Check 4: Existing incidents
print("\n4. CHECKING EXISTING INCIDENTS:")
incidents = Incident.objects.all().order_by('-created_at')[:5]
if incidents.count() == 0:
    print("   No incidents created yet")
else:
    for inc in incidents:
        print(f"   • {inc.incident_id} - {inc.incident_type} ({inc.severity}) - {inc.status}")

# Check 5: Audit logs
print("\n5. CHECKING AUDIT LOGS FOR ALERTS:")
logs = AuditLog.objects.filter(action='emergency_alert').order_by('-timestamp')[:5]
if logs.count() == 0:
    print("   No emergency alerts triggered yet")
else:
    for log in logs:
        print(f"   • {log.created_at}: {log.actor.name} triggered alert {log.target_id}")

print("\n" + "=" * 70)
print("RECOMMENDATIONS:")
print("=" * 70)

if users.count() == 0:
    print("❌ PROBLEM: No users in database")
    print("   SOLUTION: Add users via Django admin or mobile app login")
    
users_without_tokens = users.filter(fcm_token__isnull=True) | users.filter(fcm_token='')
if users_without_tokens.count() > 0:
    print(f"⚠️  WARNING: {users_without_tokens.count()} users have no FCM token")
    print("   REASON: They haven't logged into the mobile app")
    print("   SOLUTION: Log into mobile app to register device token")
    
if users.filter(fcm_token__isnull=False).exclude(fcm_token='').count() > 0:
    print("✅ Some users have FCM tokens - alerts CAN be sent to them")
    
print("\n" + "=" * 70)
