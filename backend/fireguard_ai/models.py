from django.db import models
from django.utils import timezone


# =========================
# FIREBASE HELPER
# =========================
def push_to_firebase(collection, doc_id, data):

    from .firebase import db

    try:
        db.collection(collection).document(str(doc_id)).set(data, merge=True)
    except Exception as e:
        print("Firebase Sync Error:", e)


# =========================
# USERS
# =========================
class UserProfile(models.Model):

    uid = models.CharField(max_length=100, unique=True)
    
    # Enterprise Compliance
    is_active = models.BooleanField(default=True)
    last_modified = models.DateTimeField(auto_now=True)

    name = models.CharField(max_length=100)
    email = models.EmailField()
    role = models.CharField(max_length=50)

    phone = models.CharField(max_length=20)

    building_id = models.CharField(max_length=50)
    block = models.CharField(max_length=10)
    house = models.CharField(max_length=20)

    created_at = models.DateTimeField(default=timezone.now)

    fcm_token = models.CharField(max_length=255, blank=True, null=True)

    designation = models.CharField(max_length=100, blank=True, null=True)

    def save(self, *args, **kwargs):

        super().save(*args, **kwargs)

        push_to_firebase(
            "users",
            self.uid,
            {
                "name": self.name,
                "email": self.email,
                "phone": self.phone,
                "role": self.role,
                "designation": self.designation,
                "buildingId": self.building_id,
                "block": self.block,
                "house": self.house,
                "society": {
                    "name": self.building_id,
                    "block": self.block
                },
                "createdAt": self.created_at,
            },
        )

    def __str__(self):
        return f"{self.name} ({self.role})"


# =========================
# DEVICES
# =========================
class Device(models.Model):

    device_id = models.CharField(max_length=100, unique=True)

    owner = models.ForeignKey(
        UserProfile,
        on_delete=models.CASCADE,
        related_name="devices",
    )

    building_id = models.CharField(max_length=50)
    block = models.CharField(max_length=10)
    house = models.CharField(max_length=20)

    status = models.CharField(max_length=30)

    installed_at = models.DateTimeField(default=timezone.now)

    def save(self, *args, **kwargs):

        super().save(*args, **kwargs)

        push_to_firebase(
            "devices",
            self.device_id,
            {
                "ownerUid": self.owner.uid,
                "buildingId": self.building_id,
                "block": self.block,
                "house": self.house,
                "status": self.status,
                "installedAt": self.installed_at,
            },
        )

    def __str__(self):
        return self.device_id


# =========================
# BLOCK INDEX
# =========================
class BlockIndex(models.Model):

    building_id = models.CharField(max_length=50)
    block = models.CharField(max_length=10)
    house = models.CharField(max_length=20)

    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE)

    def save(self, *args, **kwargs):

        super().save(*args, **kwargs)

        push_to_firebase(
            "blockIndex",
            self.building_id,
            {
                self.block: {self.house: self.user.uid},
            },
        )

    def __str__(self):
        return f"{self.building_id}-{self.block}-{self.house}"


# =========================
# BLOCK MANAGER
# =========================
class BlockManager(models.Model):

    building_id = models.CharField(max_length=50)
    block = models.CharField(max_length=10)

    name = models.CharField(max_length=100)
    phone = models.CharField(max_length=20)

    user = models.OneToOneField(UserProfile, on_delete=models.CASCADE)

    def save(self, *args, **kwargs):

        super().save(*args, **kwargs)

        push_to_firebase(
            "blockManagers",
            self.building_id,
            {
                self.block: {
                    "name": self.name,
                    "phone": self.phone,
                    "uid": self.user.uid,
                }
            },
        )

    def __str__(self):
        return f"{self.name} ({self.block})"


# =========================
# AUTHORITIES
# =========================
class Authority(models.Model):

    ROLE_CHOICES = [
        ("secretary", "Secretary"),
        ("chairman", "Chairman"),
    ]

    building_id = models.CharField(max_length=50)

    role = models.CharField(max_length=20, choices=ROLE_CHOICES)

    name = models.CharField(max_length=100)
    phone = models.CharField(max_length=20)

    user = models.OneToOneField(UserProfile, on_delete=models.CASCADE)

    def save(self, *args, **kwargs):

        super().save(*args, **kwargs)

        push_to_firebase(
            "authorities",
            self.building_id,
            {
                self.role: {
                    "name": self.name,
                    "phone": self.phone,
                    "uid": self.user.uid,
                }
            },
        )

    def __str__(self):
        return f"{self.role} - {self.name}"


# =========================
# FIRE DEPARTMENT
# =========================
class FireDepartment(models.Model):

    building_id = models.CharField(max_length=50)

    station_name = models.CharField(max_length=200)
    phone = models.CharField(max_length=20)

    station_id = models.CharField(max_length=100, unique=True)

    def save(self, *args, **kwargs):

        super().save(*args, **kwargs)

        push_to_firebase(
            "fireDepartment",
            self.building_id,
            {
                "stationName": self.station_name,
                "phone": self.phone,
                "stationId": self.station_id,
            },
        )

    def __str__(self):
        return self.station_name


# =========================
# INCIDENTS
# =========================
class Incident(models.Model):

    INCIDENT_TYPE = [
        ("fire", "Fire"),
        ("gas", "Gas Leak"),
    ]

    STATUS = [
        ("active", "Active"),
        ("resolved", "Resolved"),
    ]

    incident_id = models.CharField(max_length=100, unique=True)

    device = models.ForeignKey(Device, on_delete=models.CASCADE)

    incident_type = models.CharField(max_length=20, choices=INCIDENT_TYPE)
    severity = models.CharField(max_length=20)

    status = models.CharField(max_length=20, choices=STATUS)

    created_at = models.DateTimeField(default=timezone.now)

    def save(self, *args, **kwargs):

        super().save(*args, **kwargs)

        push_to_firebase(
            "incidents",
            self.incident_id,
            {
                "deviceId": self.device.device_id,
                "buildingId": self.device.building_id,
                "block": self.device.block,
                "house": self.device.house,
                "type": self.incident_type,
                "severity": self.severity,
                "status": self.status,
                "createdAt": self.created_at,
                "victimPhone": self.device.owner.phone if self.device.owner else "",
                "flat": self.device.house,
            },
        )

    def __str__(self):
        return self.incident_id


# =========================
# ALERTS
# =========================
class Alert(models.Model):

    alert_id = models.CharField(max_length=100, unique=True)

    incident = models.ForeignKey(
        Incident, on_delete=models.CASCADE, related_name="alerts"
    )

    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE)

    role = models.CharField(max_length=50)
    phone = models.CharField(max_length=20)

    priority = models.IntegerField()

    status = models.CharField(max_length=30)

    time = models.DateTimeField(default=timezone.now)

    def save(self, *args, **kwargs):

        super().save(*args, **kwargs)

        payload = {
                "uid": self.user.uid,
                "role": self.role,
                "phone": self.phone,
                "priority": self.priority,
                "status": self.status,
                "time": self.time,
                # Query Fields (Critical for Mobile)
                "societyName": self.incident.device.building_id,
                "buildingId": self.incident.device.building_id,
                "block": self.incident.device.block,
                "type": self.incident.incident_type,
            }
        
        print(f"DEBUG: Pushing Alert to Firebase: {payload}")

        push_to_firebase(
            "alerts",
            self.alert_id,
            payload,
        )

    def __str__(self):
        return self.alert_id


# =========================
# AI RESPONSES
# =========================
class AIResponse(models.Model):

    incident = models.OneToOneField(Incident, on_delete=models.CASCADE)

    message = models.TextField()
    level = models.CharField(max_length=30)

    generated_at = models.DateTimeField(default=timezone.now)

    def save(self, *args, **kwargs):

        super().save(*args, **kwargs)

        push_to_firebase(
            "aiResponses",
            self.incident.incident_id,
            {
                "message": self.message,
                "level": self.level,
                "generatedAt": self.generated_at,
            },
        )

    def __str__(self):
        return self.incident.incident_id


# =========================
# LIVE DATA
# =========================
class LiveData(models.Model):

    device = models.OneToOneField(Device, on_delete=models.CASCADE)

    gas = models.IntegerField()
    flame = models.BooleanField()
    temp = models.IntegerField()
    sprinkler = models.BooleanField(default=False) # Added for live status

    updated_at = models.DateTimeField(auto_now=True)

    def save(self, *args, **kwargs):

        super().save(*args, **kwargs)

        push_to_firebase(
            "liveData",
            self.device.device_id,
            {
                "gas": self.gas,
                "flame": self.flame,
                "temp": self.temp,
                "sprinkler": self.sprinkler,
                "updatedAt": self.updated_at,
                "location": f"{self.device.building_id} - {self.device.block}",
            },
        )

    def __str__(self):
        return self.device.device_id


# =========================
# LOGS
# =========================
class Log(models.Model):

    log_id = models.CharField(max_length=100, unique=True)

    action = models.CharField(max_length=200)

    user = models.ForeignKey(
        UserProfile, on_delete=models.SET_NULL, null=True
    )

    time = models.DateTimeField(default=timezone.now)

    def save(self, *args, **kwargs):

        super().save(*args, **kwargs)

        push_to_firebase(
            "logs",
            self.log_id,
            {
                "action": self.action,
                "uid": self.user.uid if self.user else "system",
                "time": self.time,
            },
        )

    def __str__(self):
        return self.log_id


# =========================
# SETTINGS
# =========================
class UserSetting(models.Model):

    user = models.OneToOneField(UserProfile, on_delete=models.CASCADE)

    gas_limit = models.IntegerField()

    auto_sprinkler = models.BooleanField(default=True)
    notify_neighbours = models.BooleanField(default=True)
    notify_authorities = models.BooleanField(default=True)

    def save(self, *args, **kwargs):

        super().save(*args, **kwargs)

        push_to_firebase(
            "settings",
            self.user.uid,
            {
                "gasLimit": self.gas_limit,
                "autoSprinkler": self.auto_sprinkler,
                "notifyNeighbours": self.notify_neighbours,
                "notifyAuthorities": self.notify_authorities,
            },
        )


# =========================
# AUDIT LOGS (ENTERPRISE)
# =========================
class AuditLog(models.Model):
    
    ACTION_CHOICES = [
        ('create', 'Create'),
        ('update', 'Update'),
        ('delete', 'Delete'),
        ('login', 'Login'),
        ('access_denied', 'Access Denied'),
    ]

    log_id = models.CharField(max_length=100, unique=True, editable=False)
    
    actor = models.ForeignKey(
        UserProfile, 
        on_delete=models.SET_NULL, 
        null=True, 
        related_name="audit_logs"
    )
    
    action = models.CharField(max_length=20, choices=ACTION_CHOICES)
    target_model = models.CharField(max_length=50) # e.g., "Device", "Incident"
    target_id = models.CharField(max_length=100)   # ID of the affected object
    
    details = models.JSONField(default=dict)       # Changes made, IP address, etc.
    
    timestamp = models.DateTimeField(default=timezone.now)

    def save(self, *args, **kwargs):
        if not self.log_id:
            import uuid
            self.log_id = f"audit_{uuid.uuid4().hex[:12]}"
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.action} - {self.target_model} - {self.timestamp}"
