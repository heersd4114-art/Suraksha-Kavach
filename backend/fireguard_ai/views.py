from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.utils import timezone

import json
import uuid
import os

from firebase_admin import credentials, messaging
import firebase_admin
from .firebase import db


from .models import (
    UserProfile,
    Alert,
    Device,
    AuditLog,
    Incident,
    LiveData  # Added LiveData
)


# =====================================================
# FIREBASE INITIALIZATION (ONE TIME)
# =====================================================

if not firebase_admin._apps:

    BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    cred_path = os.path.join(
        BASE_DIR,
        "firebase_key.json"
    )

    cred = credentials.Certificate(cred_path)

    firebase_admin.initialize_app(cred)


# =====================================================
# PUSH NOTIFICATION ENGINE
# =====================================================

# =====================================================
# PUSH NOTIFICATION ENGINE
# =====================================================

def send_push_notification(tokens, title, body, data=None):

    if not tokens:
        return 0

    success_count = 0
    failure_count = 0
    
    # Chunk tokens into batches of 500 (Firebase Limit)
    batch_size = 500
    
    for i in range(0, len(tokens), batch_size):
        batch_tokens = tokens[i:i + batch_size]
        
        try:
            message = messaging.MulticastMessage(
                notification=messaging.Notification(
                    title=title,
                    body=body
                ),
                data=data or {},
                tokens=batch_tokens
            )
            
            response = messaging.send_each_for_multicast(message)
            
            success_count += response.success_count
            failure_count += response.failure_count
            
            if response.failure_count > 0:
                print(f"Batch {i//batch_size + 1}: {response.failure_count} failures")
                for idx, resp in enumerate(response.responses):
                    if not resp.success:
                        print(f" - Token: {batch_tokens[idx][:10]}... Error: {resp.exception}")
                        
        except Exception as e:
            print(f"Batch Send Error: {e}")
            # Fallback to individual sending if batch fails completely (robustness)
            for token in batch_tokens:
                try:
                    msg = messaging.Message(
                        notification=messaging.Notification(
                            title=title,
                            body=body
                        ),
                        data=data or {},
                        token=token
                    )
                    messaging.send(msg)
                    success_count += 1
                except Exception as inner_e:
                    print(f"Individual Send Error: {inner_e}")
                    failure_count += 1

    print(f"Push Result: {success_count} sent, {failure_count} failed")
    
    return success_count


# =====================================================
# DASHBOARD
# =====================================================

@csrf_exempt
def dashboard_view(request):

    admin_uid = ""

    try:

        admin = UserProfile.objects.filter(
            role__in=["owner", "admin"]
        ).first()

        if not admin:
            pass

        if admin and not Device.objects.filter(owner=admin).exists():

            Device.objects.create(
                device_id="SYS_MASTER_01",
                owner=admin,
                building_id="FireGuard HQ",
                block="A",
                house="001",
                status="active"
            )

        if admin:
            admin_uid = admin.uid
        else:
            # Fallback: Try to get ANY user from Firestore to act as admin for the dashboard
            try:
                users_ref = db.collection("users").limit(1).stream()
                for doc in users_ref:
                    admin_uid = doc.id
                    break
                else:
                    admin_uid = "temp_dashboard_admin"
            except:
                admin_uid = "temp_dashboard_admin"

    except Exception as e:

        print("Dashboard Error:", e)

        admin_uid = "fallback_admin"

    incidents = Incident.objects.all().order_by("-created_at")

    # Fetch Live Data for Dashboard (Initial Render)
    live_data = None
    try:
        if admin:
             device = Device.objects.filter(owner=admin).first()
             if device:
                 live_data = LiveData.objects.filter(device=device).first()
    except Exception as e:
        print("Live Data Fetch Error:", e)

    return render(
        request,
        "fireguard_ai/alert_dashboard.html",
        {
            "incidents": incidents,
            "admin_uid": admin_uid,
            "live_data": live_data
        }
    )


# =====================================================
# BROADCAST ALERT (MAIN ENGINE)
# =====================================================

@csrf_exempt
def broadcast_alert(request):

    if request.method != "POST":

        return JsonResponse(
            {"error": "Method not allowed"},
            status=405
        )

    try:

        data = json.loads(request.body)

        # ================= USER =================

        uid = request.headers.get("X-User-ID")

        user = UserProfile.objects.filter(uid=uid).first()
        
        if not user:
            return JsonResponse(
                {"error": "Unauthorized: Invalid or missing X-User-ID"},
                status=401
            )

        # ================= PAYLOAD =================

        incident_type = data.get("type", "emergency")
        severity = data.get("severity", "high")
        block = data.get("block", user.block)

        incident_id = f"INC-{uuid.uuid4().hex[:8]}"
        alert_id = f"ALT-{uuid.uuid4().hex[:8]}"

        society = data.get("society")

        if not society:

            resident = UserProfile.objects.filter(
                block=block
            ).first()

            society = (
                resident.building_id
                if resident
                else user.building_id
            )

        # ================= DEVICE =================

        device = Device.objects.filter(
            block=block,
            building_id=society
        ).first()

        if not device:

            device = Device.objects.create(
                device_id=f"VIRTUAL-{block}-{uuid.uuid4().hex[:4]}",
                owner=user,
                building_id=society,
                block=block,
                house="ADMIN",
                status="active"
            )

        # ================= INCIDENT =================

        incident = Incident.objects.create(
            incident_id=incident_id,
            device=device,
            incident_type=incident_type,
            severity=severity,
            status="active"
        )

        # ================= AUDIT =================

        AuditLog.objects.create(
            actor=user,
            action="broadcast",
            target_model="Alert",
            target_id=alert_id,
            details={
                "type": incident_type,
                "block": block,
                "severity": severity
            }
        )

        # ================= ALERT =================

        alert = Alert.objects.create(
            alert_id=alert_id,
            incident=incident,
            user=user,
            role=user.role,
            phone=user.phone,
            priority=1 if severity == "high" else 2,
            status="active"
        )

        # ================= USERS FETCH (OPTIMIZED) =================
        
        tokens = []
        try:
            # 1. Fetch relevant users from SQL (e.g. same building)
            # This is much faster than scanning Firestore if you have thousands of users.
            # Assuming 'building_id' is the filter key.
            
            # Fetch SQL users in target building
            target_users = UserProfile.objects.filter(building_id=society)
            
            # 2. Get their UIDs or FCM tokens directly if stored in SQL
            # If FCM token is in SQL:
            for u in target_users:
                if u.fcm_token:
                    tokens.append(u.fcm_token)
            
            # 3. IF tokens are NOT in SQL (only in Firestore), use Firestore Query
            # BUT query by buildingId to avoid fetching everyone
            if not tokens:
                users_ref = db.collection("users")
                # Query: buildingId == society
                query = users_ref.where("buildingId", "==", society).stream()
                
                for doc in query:
                    user_data = doc.to_dict()
                    token = user_data.get("fcmToken") or user_data.get("fcm_token")
                    if token:
                        tokens.append(token)
            
            # If still no tokens, fallback to fetching all (legacy behavior - discouraged)
            if not tokens:
                print("Warning: No target users found in SQL/Firestore filter. Broadcasting to ALL (Fallback).")
                docs = db.collection("users").stream()
                for doc in docs:
                    user_data = doc.to_dict()
                    token = user_data.get("fcmToken") or user_data.get("fcm_token")
                    if token:
                        tokens.append(token)

        except Exception as e:
            print(f"Error fetching tokens: {e}")
            # Safety net
            pass

        print(f"Tokens found: {len(tokens)}") # DEBUG LOG


        # Duplicate removal
        tokens = list(set(tokens))

        # ================= PUSH =================

        if severity == "high":
            title = f"EMERGENCY: {incident_type.upper()} ALERT"
        else:
            title = f"FIREGUARD ALERT: {incident_type.upper()}"

        body = f"Incident in Block {block}. Act Now!"

        payload = {
            "title": title, # Explicitly add title to data payload for Flutter background handler
            "body": body,
            "alert_id": alert_id,
            "incident_id": incident_id,
            "type": incident_type,
            "severity": severity,
            "block": block,
            "society": society,
            "click_action": "FLUTTER_NOTIFICATION_CLICK" # Helps Android routing
        }

        print(f"Sending push notification to {len(tokens)} tokens") # DEBUG LOG

        sent_count = send_push_notification(
            tokens,
            title,
            body,
            payload
        )
        
        print(f"Notifications sent: {sent_count}") # DEBUG LOG


        # ================= RESPONSE =================

        return JsonResponse({

            "status": "success",

            "alert_id": alert_id,

            "incident_id": incident_id,
            

            "target_users": len(tokens),

            "notifications_sent": sent_count,

            "actor": user.name

        })


    except Exception as e:

        print("Broadcast Failed:", e)

        return JsonResponse(
            {"error": str(e)},
            status=500
        )


# =====================================================
# DEVICE CONTROL
# =====================================================

# =========================
# LIVE DATA & DASHBOARD
# =========================

@csrf_exempt
def update_live_data(request):
    """
    Called by ESP32 every 3s to update sensor readings.
    """
    if request.method == "POST":
        config = request.headers.get("X-User-ID")
        # In this prototype, we'll use a fixed device or fetch based on UID if available
        # For simplicity, we'll update the first available device or specific one
        
        try:
            print("Received Live Data Request") # DEBUG
            data = json.loads(request.body)
            print(f"Payload: {data}") # DEBUG
            # data = { gas_level, temperature, sprinkler_status, flame_detected }
            
            # Find device
            # Ideally should use Device ID, but fallback to User ID
            user = UserProfile.objects.filter(uid=config).first()
            if user:
                 device = Device.objects.filter(owner=user).first()
            else:
                 device = Device.objects.first() # Fallback for demo
            
            if not device:
                return JsonResponse({"error": "No device found"}, status=404)

            # Update or Create Live Data
            live_data, created = LiveData.objects.get_or_create(device=device)
            
            live_data.gas = data.get("gas_level", 0)
            live_data.temp = data.get("temperature", 25)
            live_data.sprinkler = data.get("sprinkler_status", False)
            live_data.flame = data.get("flame_detected", False)
            
            live_data.save() # Triggers Firestore Sync

            return JsonResponse({"status": "updated"})

        except Exception as e:
            print(f"Live Update Error: {e}")
            return JsonResponse({"error": str(e)}, status=500)

    return JsonResponse({"error": "POST required"}, status=400)


def get_live_status(request):
    """
    Called by Mobile App to get red/green status and sensor data.
    """
    uid = request.GET.get("uid")
    user = UserProfile.objects.filter(uid=uid).first()
    
    if user:
        device = Device.objects.filter(owner=user).first()
    else:
        device = Device.objects.first() # Demo fallback

    if not device:
        return JsonResponse({"status": "SECURE", "color": "green", "data": {}})

    try:
        data = LiveData.objects.get(device=device)
        
        # Logic for Status
        # ALERT if Flame is True OR Gas > 30 (adjust threshold as needed)
        is_danger = data.flame or (data.gas > 30)
        
        status = "ALERT" if is_danger else "SECURE"
        color = "red" if is_danger else "green"

        response_data = {
            "status": status,
            "color": color,
            "data": {
                "gas": data.gas,
                "temp": data.temp,
                "sprinkler": data.sprinkler,
                "flame": data.flame,
                "last_updated": data.updated_at
            }
        }
        return JsonResponse(response_data)

    except LiveData.DoesNotExist:
        return JsonResponse({
            "status": "SECURE", 
            "color": "green", 
            "data": {"gas": 0, "temp": 0, "sprinkler": False}
        })

@csrf_exempt
def update_device_status(request):

    if request.method != "POST":

        return JsonResponse(
            {"error": "Method not allowed"},
            status=405
        )

    try:

        data = json.loads(request.body)

        uid = request.headers.get("X-User-ID")

        user = UserProfile.objects.filter(uid=uid).first()

        if not user:
            user = UserProfile.objects.first()

        device_id = data.get("device_id")
        status = data.get("status")

        if not device_id or not status:

            return JsonResponse(
                {"error": "Missing fields"},
                status=400
            )

        device = Device.objects.get(device_id=device_id)

        old = device.status

        device.status = status

        device.save()

        AuditLog.objects.create(
            actor=user,
            action="update",
            target_model="Device",
            target_id=device_id,
            details={
                "old": old,
                "new": status
            }
        )

        return JsonResponse({

            "status": "success",

            "message": f"{device_id} updated"

        })


    except Device.DoesNotExist:

        return JsonResponse(
            {"error": "Device not found"},
            status=404
        )


    except Exception as e:

        return JsonResponse(
            {"error": str(e)},
            status=500
        )


# =====================================================
# FIREBASE TEST
# =====================================================

@csrf_exempt
def test_firebase(request):

    try:

        test_token = UserProfile.objects.exclude(
            fcm_token=""
        ).first()

        if not test_token:

            return JsonResponse({
                "status": "error",
                "message": "No tokens registered"
            })

        sent = send_push_notification(

            [test_token.fcm_token],

            "🔥 Test Alert",

            "Firebase connection OK",

            {"test": "true"}

        )

        return JsonResponse({

            "status": "online",

            "sent": sent

        })


    except Exception as e:

        return JsonResponse({

            "status": "error",

            "message": str(e)

        }, status=500)


# =====================================================
# USER MANAGEMENT (NEW)
# =====================================================

def get_all_users(request):
    
    try:
        users = UserProfile.objects.all()
        data = []
        
        for user in users:
            data.append({
                "uid": user.uid,
                "name": user.name,
                "email": user.email,
                "role": user.role,
                "designation": user.designation or user.role, # Fallback
                "building_id": user.building_id,
            })
            
        return JsonResponse({"users": data})
        
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


# =====================================================
# PROFESSIONAL DASHBOARD (SSIP READY)
# =====================================================

@csrf_exempt
def professional_dashboard_view(request):
    """
    Professional dashboard with:
    - Designation-based access control
    - Live analytics
    - Real-time monitoring
    - Role-specific data views
    """
    
    try:
        # Get authenticated user or fallback
        uid = request.headers.get("X-User-ID", None)
        user = None
        
        if uid:
            user = UserProfile.objects.filter(uid=uid).first()
        
        if not user:
            user = UserProfile.objects.filter(
                role__in=["owner", "admin"]
            ).first()
        
        # Prepare dashboard context
        all_devices = Device.objects.all().order_by("-installed_at")
        active_incidents = Incident.objects.filter(
            status="active"
        ).order_by("-created_at")
        
        recent_alerts = Alert.objects.all().order_by("-time")[:10]
        all_users = UserProfile.objects.filter(is_active=True)
        
        # Get live data
        live_data_list = LiveData.objects.all().order_by("-updated_at")[:5]
        
        # Metrics
        total_devices = all_devices.count()
        active_devices = all_devices.filter(status="active").count()
        total_incidents = Incident.objects.count()
        critical_incidents = Incident.objects.filter(
            severity__in=["high", "critical"]
        ).count()
        
        # Role-based filtering
        designation = user.designation if user else "Guest"
        role = user.role if user else "viewer"
        
        # Safety Officer sees: All systems, All incidents, All alerts
        # Plant Manager sees: All systems, Performance metrics, Staff
        # Supervisor sees: Assigned zone, Status updates
        # Analyst sees: Data only (read-only)
        
        context = {
            "user": user,
            "designation": designation,
            "role": role,
            "devices": all_devices,
            "active_devices": active_devices,
            "total_devices": total_devices,
            "incidents": active_incidents,
            "total_incidents": total_incidents,
            "critical_incidents": critical_incidents,
            "recent_alerts": recent_alerts,
            "users": all_users,
            "live_data": live_data_list,
            "admin_uid": user.uid if user else "system",
        }
        
        return render(
            request,
            "fireguard_ai/dashboard.html",
            context
        )
        
    except Exception as e:
        print(f"Professional Dashboard Error: {e}")
        return JsonResponse(
            {"error": str(e)},
            status=500
        )


# =====================================================
# API: GET DASHBOARD DATA (JSON)
# =====================================================

@csrf_exempt
def get_dashboard_data(request):
    """
    API endpoint for real-time dashboard data.
    Returns JSON for AJAX/API clients.
    """
    
    try:
        uid = request.headers.get("X-User-ID", None)
        user = UserProfile.objects.filter(uid=uid).first() if uid else None
        
        devices = Device.objects.all()
        live_data = LiveData.objects.filter(
            device__in=devices
        ).order_by("-updated_at")[:1]
        
        incidents = Incident.objects.filter(status="active")
        
        data = {
            "status": "success",
            "user": {
                "uid": user.uid if user else None,
                "name": user.name if user else "Guest",
                "role": user.role if user else "viewer",
                "designation": user.designation if user else "Guest"
            },
            "metrics": {
                "total_devices": devices.count(),
                "active_devices": devices.filter(status="active").count(),
                "active_incidents": incidents.count(),
                "critical_incidents": incidents.filter(severity__in=["high", "critical"]).count(),
                "total_users": UserProfile.objects.filter(is_active=True).count()
            },
            "live": {
                "gas": live_data[0].gas if live_data else 0,
                "temperature": live_data[0].temp if live_data else 0,
                "flame": live_data[0].flame if live_data else False,
                "sprinkler": live_data[0].sprinkler if live_data else False,
                "timestamp": str(live_data[0].updated_at) if live_data else None
            },
            "incidents": [{
                "id": inc.incident_id,
                "type": inc.incident_type,
                "severity": inc.severity,
                "status": inc.status,
                "timestamp": str(inc.created_at)
            } for inc in incidents[:5]]
        }
        
        return JsonResponse(data)
        
    except Exception as e:
        return JsonResponse(
            {"error": str(e)},
            status=500
        )


# =====================================================
# API: GET DESIGNATION-BASED ACCESS
# =====================================================

@csrf_exempt
def get_designation_access(request):
    """
    Returns access permissions based on user designation.
    """
    
    try:
        uid = request.headers.get("X-User-ID", None)
        user = UserProfile.objects.filter(uid=uid).first() if uid else None
        
        designation = user.designation if user else "Guest"
        
        access_map = {
            "Safety Officer": {
                "can_view_all": True,
                "can_edit_all": True,
                "can_broadcast": True,
                "can_manage_users": True,
                "access_level": "FULL"
            },
            "Plant Manager": {
                "can_view_all": True,
                "can_edit_all": True,
                "can_broadcast": False,
                "can_manage_users": True,
                "access_level": "ADMINISTRATIVE"
            },
            "Supervisor": {
                "can_view_all": False,
                "can_edit_all": False,
                "can_broadcast": False,
                "can_manage_users": False,
                "access_level": "LIMITED"
            },
            "Analyst": {
                "can_view_all": True,
                "can_edit_all": False,
                "can_broadcast": False,
                "can_manage_users": False,
                "access_level": "READ_ONLY"
            }
        }
        
        permissions = access_map.get(designation, access_map["Analyst"])
        
        return JsonResponse({
            "status": "success",
            "user": {
                "uid": user.uid if user else None,
                "name": user.name if user else "Guest",
                "designation": designation
            },
            "permissions": permissions
        })
        
    except Exception as e:
        return JsonResponse(
            {"error": str(e)},
            status=500
        )


# =====================================================
# EMERGENCY ALERT ENDPOINT
# =====================================================

@csrf_exempt
def trigger_emergency_alert(request):
    """
    One-click emergency alert trigger from dashboard.
    Sends immediate notifications to all personnel.
    """
    
    if request.method != "POST":
        return JsonResponse(
            {"error": "Method not allowed"},
            status=405
        )
    
    try:
        data = json.loads(request.body)
        uid = request.headers.get("X-User-ID")
        
        # Get user
        user = UserProfile.objects.filter(uid=uid).first()
        if not user:
            return JsonResponse(
                {"error": "Unauthorized"},
                status=401
            )
        
        # Generate IDs
        incident_id = f"INC-{uuid.uuid4().hex[:8].upper()}"
        alert_id = f"ALT-{uuid.uuid4().hex[:8].upper()}"
        
        # Get device (first available or create virtual)
        device = Device.objects.filter(status="active").first()
        if not device:
            device = Device.objects.create(
                device_id=f"VIRTUAL-{uuid.uuid4().hex[:6]}",
                owner=user,
                building_id=user.building_id,
                block=user.block or "A",
                house="EMERGENCY",
                status="active"
            )
        
        # Create incident
        incident = Incident.objects.create(
            incident_id=incident_id,
            device=device,
            incident_type="EMERGENCY_MANUAL",
            severity="critical",
            status="active"
        )
        
        # Create alert
        alert = Alert.objects.create(
            alert_id=alert_id,
            incident=incident,
            user=user,
            role=user.role,
            phone=user.phone or "+91-emergency",
            priority=1,
            status="active"
        )
        
        # Log action
        AuditLog.objects.create(
            actor=user,
            action="emergency_alert",
            target_model="Alert",
            target_id=alert_id,
            details={
                "type": "MANUAL_EMERGENCY",
                "triggered_by": user.name,
                "building": user.building_id
            }
        )
        
        # Get all active users' tokens
        tokens = []
        all_users = UserProfile.objects.filter(is_active=True)
        for u in all_users:
            if u.fcm_token:
                tokens.append(u.fcm_token)
        
        # Remove duplicates
        tokens = list(set(tokens))
        
        # Send push notification
        notification_count = send_push_notification(
            tokens,
            "🚨 EMERGENCY ALERT - MANUAL TRIGGER",
            f"Critical incident activated by {user.name}. All personnel must respond immediately!",
            {
                "alert_id": alert_id,
                "incident_id": incident_id,
                "type": "EMERGENCY",
                "severity": "CRITICAL",
                "actor": user.name,
                "building": user.building_id,
                "click_action": "FLUTTER_NOTIFICATION_CLICK"
            }
        )
        
        return JsonResponse({
            "status": "success",
            "message": "EMERGENCY ALERT SENT",
            "alert_id": alert_id,
            "incident_id": incident_id,
            "notifications_sent": notification_count,
            "personnel_notified": len(tokens),
            "triggered_by": user.name,
            "timestamp": str(alert.time)
        })
        
    except Exception as e:
        print(f"Emergency Alert Error: {e}")
        return JsonResponse(
            {"error": str(e)},
            status=500
        )

