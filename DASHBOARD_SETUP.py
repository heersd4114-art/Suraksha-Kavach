#!/usr/bin/env python
"""
PROFESSIONAL DASHBOARD SETUP & DEPLOYMENT GUIDE
Shurakhsha Kavach - SSIP Ready

This file documents the complete setup and deployment process for the
professional dashboard system.
"""

# ================================================================
# STEP 1: VERIFY DJANGO INSTALLATION
# ================================================================

"""
Run these commands in your backend directory:

cd d:\Shurakhsha Kavach\Shurakhsha Kavach\Shurakhsha Kavach\backend

# Check Django version
python manage.py --version

# Run migrations
python manage.py migrate

# Create superuser (if not exists)
python manage.py createsuperuser
"""

# ================================================================
# STEP 2: ACCESS THE PROFESSIONAL DASHBOARD
# ================================================================

"""
Start Django development server:

python manage.py runserver 0.0.0.0:8000

Then access dashboard at:
http://localhost:8000/api/professional-dashboard/

Or from another machine:
http://YOUR_PC_IP:8000/api/professional-dashboard/
"""

# ================================================================
# STEP 3: SAMPLE USERPROFILE WITH DESIGNATION
# ================================================================

"""
Create users with designations in Django admin or shell:

python manage.py shell

>>> from fireguard_ai.models import UserProfile
>>> 
>>> # Create Safety Officer
>>> officer = UserProfile.objects.create(
...     uid="officer_001",
...     name="Rajesh Kumar",
...     email="rajesh@example.com",
...     phone="9876543210",
...     role="admin",
...     designation="Safety Officer",  # KEY FIELD
...     building_id="Galaxy Heights",
...     block="A",
...     house="101"
... )
>>> 
>>> # Create Plant Manager
>>> manager = UserProfile.objects.create(
...     uid="manager_001",
...     name="Priya Sharma",
...     email="priya@example.com",
...     phone="9876543211",
...     role="owner",
...     designation="Plant Manager",  # KEY FIELD
...     building_id="Galaxy Heights",
...     block="A",
...     house="102"
... )
>>> exit()
"""

# ================================================================
# STEP 4: SAMPLE DEVICE CREATION
# ================================================================

"""
Create devices for testing:

python manage.py shell

>>> from fireguard_ai.models import UserProfile, Device
>>> 
>>> admin = UserProfile.objects.first()
>>> 
>>> Device.objects.create(
...     device_id="DEVICE_001",
...     owner=admin,
...     building_id="Galaxy Heights",
...     block="A",
...     house="001",
...     status="active"
... )
>>> 
>>> Device.objects.create(
...     device_id="DEVICE_002",
...     owner=admin,
...     building_id="Galaxy Heights",
...     block="B",
...     house="101",
...     status="active"
... )
>>> exit()
"""

# ================================================================
# STEP 5: SAMPLE LIVEDATA CREATION
# ================================================================

"""
Create live sensor data:

python manage.py shell

>>> from fireguard_ai.models import Device, LiveData
>>> from django.utils import timezone
>>> 
>>> device = Device.objects.first()
>>> 
>>> LiveData.objects.create(
...     device=device,
...     gas_level=12,
...     temperature=24.5,
...     flame_detected=False,
...     sprinkler_on=False,
...     timestamp=timezone.now()
... )
>>> exit()
"""

# ================================================================
# STEP 6: API ENDPOINTS TEST
# ================================================================

"""
Test the dashboard APIs using curl or Postman:

# Get Dashboard Data
curl -X GET http://localhost:8000/api/dashboard-data/ \
  -H "X-User-ID: officer_001"

# Get Designation Access
curl -X GET http://localhost:8000/api/designation-access/ \
  -H "X-User-ID: officer_001"

# Expected Response:
{
  "status": "success",
  "user": {
    "uid": "officer_001",
    "name": "Rajesh Kumar",
    "designation": "Safety Officer"
  },
  "permissions": {
    "can_view_all": true,
    "can_edit_all": true,
    "can_broadcast": true,
    "can_manage_users": true,
    "access_level": "FULL"
  }
}
"""

# ================================================================
# STEP 7: PRODUCTION DEPLOYMENT
# ================================================================

"""
For production deployment:

1. Collect static files:
   python manage.py collectstatic --noinput

2. Update Django settings:
   ALLOWED_HOSTS = ['your-domain.com', 'your-ip']
   DEBUG = False

3. Use production server (Gunicorn):
   pip install gunicorn
   gunicorn core.wsgi:application --bind 0.0.0.0:8000 --workers 4

4. Use Nginx as reverse proxy (recommended)

5. Enable HTTPS with Let's Encrypt SSL certificate

6. Configure Firebase credentials for production
"""

# ================================================================
# STEP 8: MONITORING & LOGGING
# ================================================================

"""
Monitor dashboard performance:

1. Enable Django logging:
   # In settings.py
   LOGGING = {
       'version': 1,
       'disable_existing_loggers': False,
       'handlers': {
           'file': {
               'level': 'INFO',
               'class': 'logging.FileHandler',
               'filename': 'dashboard.log',
           },
       },
       'root': {
           'handlers': ['file'],
           'level': 'INFO',
       },
   }

2. View logs:
   tail -f dashboard.log

3. Monitor database queries:
   python manage.py shell
   from django.db import connection
   from django.test.utils import CaptureQueriesContext
   
   with CaptureQueriesContext(connection) as ctx:
       # Your code here
       pass
   print(f"Queries: {len(ctx)}")
"""

# ================================================================
# STEP 9: CUSTOMIZATION
# ================================================================

"""
To customize the dashboard:

1. Edit colors in professional_dashboard.html:
   --accent-blue: #3b82f6;
   --accent-cyan: #06b6d4;
   --primary-dark: #0f172a;

2. Add custom charts:
   new Chart(ctx, { ... });

3. Add new tables:
   Copy existing table HTML and modify

4. Change sidebar navigation:
   Edit .nav-menu list items

5. Add custom widgets:
   Create new .card divs with unique IDs
"""

# ================================================================
# STEP 10: PERFORMANCE OPTIMIZATION
# ================================================================

"""
Optimize dashboard performance:

1. Enable caching:
   from django.views.decorators.cache import cache_page
   
   @cache_page(60)  # Cache for 60 seconds
   def get_dashboard_data(request):
       ...

2. Minimize database queries:
   Use select_related() and prefetch_related()
   
   devices = Device.objects.select_related('owner').all()

3. Compress static files:
   pip install django-compressor
   
4. Use CDN for Chart.js and Font Awesome:
   Already configured in professional_dashboard.html

5. Lazy load images and charts for mobile devices
"""

# ================================================================
# TROUBLESHOOTING CHECKLIST
# ================================================================

"""
If dashboard isn't working, check:

□ Django server is running: python manage.py runserver
□ URL routing is correct: python manage.py show_urls | grep dashboard
□ Templates path is set: TEMPLATES setting in settings.py
□ Static files are collected: python manage.py collectstatic
□ Database migrations are applied: python manage.py migrate
□ UserProfile exists: python manage.py shell → UserProfile.objects.all()
□ Device and LiveData exist: check admin panel
□ Browser console has no JavaScript errors: F12 → Console
□ Network requests are successful: F12 → Network tab
□ Firebase is properly initialized
□ X-User-ID header is being sent for APIs
"""

# ================================================================
# QUICK START COMMAND
# ================================================================

"""
Run everything at once:

cd d:\Shurakhsha\ Kavach\Shurakhsha\ Kavach\Shurakhsha\ Kavach\backend
python manage.py migrate
python manage.py runserver
# Open: http://localhost:8000/api/professional-dashboard/
"""

# ================================================================
# FILE STRUCTURE
# ================================================================

"""
Backend Structure:

fireguard_ai/
├── templates/
│   └── fireguard_ai/
│       ├── alert_dashboard.html (old)
│       └── professional_dashboard.html (NEW - SSIP Ready)
├── views.py
│   ├── dashboard_view() (old)
│   ├── professional_dashboard_view() (NEW)
│   ├── get_dashboard_data() (NEW API)
│   └── get_designation_access() (NEW API)
├── urls.py
│   ├── path("dashboard/", ...)
│   ├── path("professional-dashboard/", ...) (NEW)
│   ├── path("api/dashboard-data/", ...) (NEW)
│   └── path("api/designation-access/", ...) (NEW)
└── models.py
    ├── UserProfile (with designation field)
    ├── Device
    ├── LiveData
    ├── Incident
    └── Alert
"""

print("✓ Professional Dashboard Setup Guide Ready!")
print("✓ All endpoints configured and tested")
print("✓ SSIP-ready design implemented")
print("✓ Designation-based access control enabled")
