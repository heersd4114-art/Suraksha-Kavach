from django.urls import path
from .views import (
    test_firebase,
    broadcast_alert,
    update_device_status,
    dashboard_view,
    update_live_data,
    get_live_status,
    get_all_users,
    professional_dashboard_view,
    get_dashboard_data,
    get_designation_access,
    trigger_emergency_alert,
)

urlpatterns = [
    path("test/", test_firebase),
    path("broadcast-alert/", broadcast_alert),
    path("update-device/", update_device_status),
    path("dashboard/", dashboard_view),
    
    # Professional Dashboard (SSIP Ready)
    path("professional-dashboard/", professional_dashboard_view),
    path("dashboard-data/", get_dashboard_data),
    path("designation-access/", get_designation_access),
    path("emergency-alert/", trigger_emergency_alert),
    
    # Live Status
    path("live/update/", update_live_data),
    path("live/status/", get_live_status),
    
    # Users
    path("users/", get_all_users),
]
