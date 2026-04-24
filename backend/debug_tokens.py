
import os
import django
import firebase_admin
from firebase_admin import credentials, firestore

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from fireguard_ai.models import UserProfile # type: ignore
from fireguard_ai.firebase import db # type: ignore

def check_tokens():
    print("--- CHECKING SQL TOKENS ---")
    users_with_tokens = UserProfile.objects.exclude(fcm_token__isnull=True).exclude(fcm_token__exact='')
    print(f"Total Users in SQL: {UserProfile.objects.count()}")
    print(f"Users with Tokens in SQL: {users_with_tokens.count()}")
    for u in users_with_tokens[:5]:
        print(f" - {u.name} ({u.building_id}): {u.fcm_token[:10]}...")

    print("\n--- CHECKING FIRESTORE TOKENS ---")
    try:
        users_ref = db.collection("users")
        # Check first 20 docs
        docs = users_ref.limit(20).stream()
        count = 0
        with_token = 0
        for doc in docs:
            count += 1
            data = doc.to_dict()
            token = data.get("fcmToken") or data.get("fcm_token")
            if token:
                with_token += 1
                if with_token <= 5:
                     print(f" - {data.get('name')} ({data.get('buildingId')}): {token[:10]}...")
        
        print(f"Checked {count} Firestore docs, found {with_token} with tokens.")

    except Exception as e:
        print(f"Firestore Error: {e}")

if __name__ == "__main__":
    check_tokens()
