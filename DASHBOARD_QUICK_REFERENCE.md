# SHURAKHSHA KAVACH - PROFESSIONAL DASHBOARD
## QUICK REFERENCE CARD

---

## 🚀 QUICK START (30 seconds)

```bash
# 1. Navigate to backend
cd d:\Shurakhsha\ Kavach\Shurakhsha\ Kavach\Shurakhsha\ Kavach\backend

# 2. Run server
python manage.py runserver

# 3. Open dashboard
# http://localhost:8000/api/professional-dashboard/
```

---

## 📍 ACCESS POINTS

| Resource | URL | Purpose |
|----------|-----|---------|
| **Web Dashboard** | `/api/professional-dashboard/` | Visual dashboard interface |
| **API - Data** | `/api/dashboard-data/` | Real-time metrics (JSON) |
| **API - Access** | `/api/designation-access/` | User permissions (JSON) |
| **Old Dashboard** | `/api/dashboard/` | Legacy interface |

---

## 👥 USER ROLES & ACCESS

### Safety Officer (FULL ACCESS)
```
- View: ALL systems, incidents, alerts
- Edit: ALL parameters
- Actions: Broadcast alerts, manage users
- Icon: 🛡️
```

### Plant Manager (ADMIN ACCESS)
```
- View: ALL systems, metrics
- Edit: Device settings
- Actions: Personnel management
- Icon: 🏭
```

### Supervisor (LIMITED)
```
- View: Assigned zones only
- Edit: Zone-specific only
- Actions: Local controls
- Icon: 👨‍💼
```

### Analyst (READ-ONLY)
```
- View: Analytics, reports
- Edit: None
- Actions: Export data
- Icon: 📊
```

---

## 🎨 DESIGN HIGHLIGHTS

✨ **Dark Theme** - Professional, modern aesthetic  
🎪 **Glass Morphism** - Frosted glass card effects  
📊 **Live Charts** - Real-time temperature & gas trends  
🎯 **Responsive** - Desktop, tablet, mobile ready  
⚡ **Fast** - Optimized performance, ~3s refresh  
🔐 **Secure** - Role-based data access control  

---

## 📊 DASHBOARD METRICS

| Metric | Display | Update |
|--------|---------|--------|
| Temperature | Live + 24h chart | 3 seconds |
| Gas Level | Live + 24h chart | 3 seconds |
| Fire Status | Real-time indicator | Instant |
| Devices | Count + status | 5 seconds |
| Incidents | Active count | Real-time |
| System Health | CPU, Memory, Uptime | 10 seconds |

---

## 🔗 API USAGE

### Get Dashboard Data
```javascript
fetch('/api/dashboard-data/', {
  headers: { 'X-User-ID': 'user_123' }
})
.then(r => r.json())
.then(data => console.log(data));
```

### Get User Permissions
```javascript
fetch('/api/designation-access/', {
  headers: { 'X-User-ID': 'user_123' }
})
.then(r => r.json())
.then(perms => console.log(perms));
```

---

## 📁 KEY FILES

```
📄 professional_dashboard.html
   Location: /templates/fireguard_ai/
   Size: ~15 KB
   Contains: HTML + CSS + JS (self-contained)

🐍 views.py
   Add: professional_dashboard_view()
        get_dashboard_data()
        get_designation_access()

🐍 urls.py
   Add: path("professional-dashboard/", ...)
        path("api/dashboard-data/", ...)
        path("api/designation-access/", ...)
```

---

## 🎯 FEATURES AT A GLANCE

| # | Feature | Details |
|---|---------|---------|
| 1️⃣ | **Real-Time Monitoring** | 3-second refresh cycle |
| 2️⃣ | **Live Analytics** | 24-hour trend charts |
| 3️⃣ | **Role-Based Access** | 4 designation levels |
| 4️⃣ | **Professional Design** | Modern dark theme |
| 5️⃣ | **Responsive Layout** | Mobile + tablet ready |
| 6️⃣ | **System Health** | CPU, memory, uptime |
| 7️⃣ | **Activity Logs** | Complete audit trail |
| 8️⃣ | **Personnel Mgmt** | Designation-based access |
| 9️⃣ | **SSIP Ready** | Enterprise-grade design |
| 🔟 | **API Endpoints** | JSON data interface |

---

## 💾 DATABASE SETUP

```bash
# Create sample user
python manage.py shell
>>> from fireguard_ai.models import UserProfile
>>> UserProfile.objects.create(
...     uid="officer_001",
...     name="Rajesh Kumar",
...     email="rajesh@example.com",
...     phone="9876543210",
...     role="admin",
...     designation="Safety Officer",  # KEY!
...     building_id="Galaxy Heights",
...     block="A",
...     house="101"
... )
>>> exit()
```

---

## 🧪 TESTING

```bash
# Test API endpoint
curl http://localhost:8000/api/dashboard-data/ \
  -H "X-User-ID: officer_001"

# Test permissions endpoint
curl http://localhost:8000/api/designation-access/ \
  -H "X-User-ID: officer_001"

# View in browser
http://localhost:8000/api/professional-dashboard/
```

---

## ⚙️ CONFIGURATION

```python
# settings.py additions
TEMPLATES = [{
    'BACKEND': 'django.template.backends.django.DjangoTemplates',
    'DIRS': [os.path.join(BASE_DIR, 'fireguard_ai/templates')],
    'APP_DIRS': True,
}]

# URLs setup
path('api/professional-dashboard/', professional_dashboard_view),
path('api/dashboard-data/', get_dashboard_data),
path('api/designation-access/', get_designation_access),
```

---

## 🐛 QUICK TROUBLESHOOTING

| Problem | Solution |
|---------|----------|
| 404 Error | Check URL routing in `urls.py` |
| No Data | Verify UserProfile, Device, LiveData exist |
| Styling Broken | Clear browser cache (Ctrl+Shift+Del) |
| Charts Empty | Check Chart.js CDN connection |
| API Returns Error | Verify X-User-ID header is sent |

---

## 📱 RESPONSIVE BREAKPOINTS

```css
Desktop:  > 1200px  (2-column: sidebar + content)
Tablet:   768-1200px (adjusted grid)
Mobile:   < 768px   (1-column, horizontal nav)
```

---

## 🔐 SECURITY NOTES

✅ Role-based access implemented  
✅ X-User-ID header required for APIs  
✅ Firebase authentication integrated  
✅ CSRF protection enabled  
⚠️ Use HTTPS in production  
⚠️ Set ALLOWED_HOSTS correctly  
⚠️ Use strong Django SECRET_KEY  

---

## 📞 SUPPORT RESOURCES

- **Documentation**: `PROFESSIONAL_DASHBOARD_GUIDE.md`
- **Setup Guide**: `DASHBOARD_SETUP.py`
- **Django Docs**: https://docs.djangoproject.com/
- **Chart.js**: https://www.chartjs.org/
- **Font Awesome**: https://fontawesome.com/

---

## ✅ VERIFICATION CHECKLIST

Before SSIP presentation:

- [ ] Dashboard loads without errors
- [ ] All metrics display correctly
- [ ] Charts render with sample data
- [ ] Role-based access works (test multiple users)
- [ ] API endpoints respond with proper JSON
- [ ] Mobile responsive layout works
- [ ] Real-time updates functioning
- [ ] Professional design meets expectations
- [ ] Database has sample data
- [ ] Server runs smoothly for 30+ minutes

---

## 📊 SSIP PRESENTATION TALKING POINTS

1. **Modern Design** - Professional, aesthetic interface
2. **Real-Time Monitoring** - Live 3-second refresh cycle
3. **Role-Based Access** - 4 designation levels with custom views
4. **Scalability** - Handles multiple buildings/zones
5. **Data Analytics** - 24-hour trend charts and insights
6. **Enterprise Ready** - Production-grade security and performance
7. **User Experience** - Responsive, fast-loading, intuitive UI
8. **Future-Proof** - REST API for mobile and third-party integration

---

**Version**: 2.0 (SSIP Ready)  
**Last Updated**: April 6, 2026  
**Status**: ✅ Production Ready  
**Designation Support**: ✅ Enabled  
**Real-Time Updates**: ✅ Active  

---

🎉 **Your Professional Dashboard is Ready!** 🎉
