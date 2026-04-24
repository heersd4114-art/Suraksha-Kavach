from django.utils import timezone

from .firebase import db

from .models import (
    UserProfile,
    Device,
    Incident,
    Alert,
    LiveData,
    AIResponse,
    UserSetting,
)


# =========================
# TIMESTAMP FIX
# =========================
def convert_ts(ts):

    if ts and hasattr(ts, "to_datetime"):
        return ts.to_datetime()

    return timezone.now()


# =========================
# USERS
# =========================
def sync_users():

    for doc in db.collection("users").stream():

        data = doc.to_dict()

        UserProfile.objects.update_or_create(
            uid=doc.id,
            defaults={
                "name": data.get("name", ""),
                "email": data.get("email", ""),
                "phone": data.get("phone", ""),
                "role": data.get("role", "owner"),
                "building_id": data.get("buildingId", ""),
                "block": data.get("block", ""),
                "house": data.get("house", ""),
                "created_at": convert_ts(data.get("createdAt")),
                "fcm_token": data.get("fcmToken") or data.get("fcm_token"),
            },
        )


# =========================
# DEVICES
# =========================
def sync_devices():

    for doc in db.collection("devices").stream():

        data = doc.to_dict()

        owner = UserProfile.objects.filter(
            uid=data.get("ownerUid")
        ).first()

        if not owner:
            continue

        Device.objects.update_or_create(
            device_id=doc.id,
            defaults={
                "owner": owner,
                "building_id": data.get("buildingId", ""),
                "block": data.get("block", ""),
                "house": data.get("house", ""),
                "status": data.get("status", "inactive"),
                "installed_at": convert_ts(data.get("installedAt")),
            },
        )


# =========================
# INCIDENTS
# =========================
def sync_incidents():

    for doc in db.collection("incidents").stream():

        data = doc.to_dict()

        device = Device.objects.filter(
            device_id=data.get("deviceId")
        ).first()

        if not device:
            continue

        Incident.objects.update_or_create(
            incident_id=doc.id,
            defaults={
                "device": device,
                "incident_type": data.get("type", "fire"),
                "severity": data.get("severity", "low"),
                "status": data.get("status", "active"),
                "created_at": convert_ts(data.get("createdAt")),
            },
        )


# =========================
# ALERTS
# =========================
def sync_alerts():

    for inc_doc in db.collection("alerts").stream():

        incident = Incident.objects.filter(
            incident_id=inc_doc.id
        ).first()

        if not incident:
            continue

        for col in db.collection("alerts").document(inc_doc.id).collections():

            for alert_doc in col.stream():

                data = alert_doc.to_dict()

                user = UserProfile.objects.filter(
                    uid=data.get("uid")
                ).first()

                if not user:
                    continue

                Alert.objects.update_or_create(
                    alert_id=alert_doc.id,
                    defaults={
                        "incident": incident,
                        "user": user,
                        "role": data.get("role", ""),
                        "phone": data.get("phone", ""),
                        "priority": data.get("priority", 1),
                        "status": data.get("status", "sent"),
                        "time": convert_ts(data.get("time")),
                    },
                )


# =========================
# LIVE DATA
# =========================
def sync_live_data():

    for doc in db.collection("liveData").stream():

        data = doc.to_dict()

        device = Device.objects.filter(
            device_id=doc.id
        ).first()

        if not device:
            continue

        LiveData.objects.update_or_create(
            device=device,
            defaults={
                "gas": data.get("gas", 0),
                "flame": data.get("flame", False),
                "temp": data.get("temp", 0),
                "updated_at": convert_ts(data.get("updatedAt")),
            },
        )


# =========================
# AI
# =========================
def sync_ai_responses():

    for doc in db.collection("aiResponses").stream():

        data = doc.to_dict()

        incident = Incident.objects.filter(
            incident_id=doc.id
        ).first()

        if not incident:
            continue

        AIResponse.objects.update_or_create(
            incident=incident,
            defaults={
                "message": data.get("message", ""),
                "level": data.get("level", "low"),
                "generated_at": convert_ts(data.get("generatedAt")),
            },
        )


# =========================
# SETTINGS
# =========================
def sync_settings():

    for doc in db.collection("settings").stream():

        data = doc.to_dict()

        user = UserProfile.objects.filter(
            uid=doc.id
        ).first()

        if not user:
            continue

        UserSetting.objects.update_or_create(
            user=user,
            defaults={
                "gas_limit": data.get("gasLimit", 1500),
                "auto_sprinkler": data.get("autoSprinkler", True),
                "notify_neighbours": data.get("notifyNeighbours", True),
                "notify_authorities": data.get("notifyAuthorities", True),
            },
        )


# =========================
# MASTER
# =========================
def sync_all():

    print(">> Users"); sync_users()
    print(">> Devices"); sync_devices()
    print(">> Incidents"); sync_incidents()
    print(">> Alerts"); sync_alerts()
    print(">> Live"); sync_live_data()
    print(">> AI"); sync_ai_responses()
    print(">> Settings"); sync_settings()

    print(">> SYNC COMPLETE")

