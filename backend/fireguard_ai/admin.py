from django.contrib import admin

from .models import (
    UserProfile,
    Device,
    BlockIndex,
    BlockManager,
    Authority,
    FireDepartment,
    Incident,
    Alert,
    AIResponse,
    LiveData,
    Log,
    UserSetting,
    AuditLog
)


# =========================
# USERS
# =========================
@admin.register(UserProfile)
class UserAdmin(admin.ModelAdmin):

    list_display = ("uid", "name", "email", "role", "block", "house", "is_active")
    search_fields = ("uid", "name", "email")
    list_filter = ("role", "block", "is_active")
    readonly_fields = ("last_modified",)


# =========================
# AUDIT LOGS (ENTERPRISE)
# =========================
@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    list_display = ("timestamp", "action", "actor", "target_model", "target_id")
    list_filter = ("action", "target_model", "timestamp")
    search_fields = ("log_id", "target_id")
    readonly_fields = ("log_id", "actor", "action", "target_model", "target_id", "details", "timestamp")

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


# =========================
# DEVICES
# =========================
@admin.register(Device)
class DeviceAdmin(admin.ModelAdmin):

    list_display = ("device_id", "owner", "status", "block", "house")
    search_fields = ("device_id",)
    list_filter = ("status", "block")


# =========================
# BLOCK INDEX
# =========================
@admin.register(BlockIndex)
class BlockIndexAdmin(admin.ModelAdmin):

    list_display = ("building_id", "block", "house", "user")
    list_filter = ("building_id", "block")


# =========================
# BLOCK MANAGERS
# =========================
@admin.register(BlockManager)
class BlockManagerAdmin(admin.ModelAdmin):

    list_display = ("name", "block", "phone", "user")


# =========================
# AUTHORITIES
# =========================
@admin.register(Authority)
class AuthorityAdmin(admin.ModelAdmin):

    list_display = ("role", "name", "phone", "building_id")
    list_filter = ("role", "building_id")


# =========================
# FIRE DEPARTMENT
# =========================
@admin.register(FireDepartment)
class FireDepartmentAdmin(admin.ModelAdmin):

    list_display = ("station_name", "station_id", "phone", "building_id")


# =========================
# INCIDENTS
# =========================
@admin.register(Incident)
class IncidentAdmin(admin.ModelAdmin):

    list_display = (
        "incident_id",
        "device",
        "incident_type",
        "severity",
        "status",
        "created_at",
    )

    list_filter = ("incident_type", "status", "severity")
    search_fields = ("incident_id", "device__device_id")


# =========================
# ALERTS
# =========================
@admin.register(Alert)
class AlertAdmin(admin.ModelAdmin):

    list_display = (
        "alert_id",
        "incident",
        "user",
        "role",
        "priority",
        "status",
        "time",
    )

    list_filter = ("status", "role", "priority")
    search_fields = ("alert_id", "incident__incident_id")


# =========================
# AI RESPONSES
# =========================
@admin.register(AIResponse)
class AIResponseAdmin(admin.ModelAdmin):

    list_display = ("incident", "level", "generated_at")
    list_filter = ("level",)


# =========================
# LIVE DATA
# =========================
@admin.register(LiveData)
class LiveDataAdmin(admin.ModelAdmin):

    list_display = ("device", "gas", "flame", "temp", "updated_at")
    list_filter = ("flame",)


# =========================
# LOGS
# =========================
@admin.register(Log)
class LogAdmin(admin.ModelAdmin):

    list_display = ("log_id", "action", "user", "time")
    search_fields = ("log_id", "action")


# =========================
# SETTINGS
# =========================
@admin.register(UserSetting)
class UserSettingAdmin(admin.ModelAdmin):

    list_display = (
        "user",
        "gas_limit",
        "auto_sprinkler",
        "notify_neighbours",
        "notify_authorities",
    )
