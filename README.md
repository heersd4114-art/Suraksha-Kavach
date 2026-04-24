<p align="center">
  <img src="fireguard_ai/assets/images/logo.png" alt="Suraksha Kavach Logo" width="150"/>
</p>

<h1 align="center">🛡️ Suraksha Kavach</h1>
<h3 align="center"><em>The Intelligent Fire Safety Shield — Defying Limits, Ensuring Safety</em></h3>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Django-092E20?style=for-the-badge&logo=django&logoColor=white" alt="Django"/>
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase"/>
  <img src="https://img.shields.io/badge/ESP32-E7352C?style=for-the-badge&logo=espressif&logoColor=white" alt="ESP32"/>
  <img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python"/>
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-1.0.0-blue?style=flat-square" alt="Version"/>
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License"/>
  <img src="https://img.shields.io/badge/status-Active-brightgreen?style=flat-square" alt="Status"/>
  <img src="https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Web-orange?style=flat-square" alt="Platform"/>
</p>

---

## 📋 Table of Contents

- [Executive Summary](#-executive-summary)
- [Problem Statement](#-problem-statement)
- [The Solution](#-the-solution--suraksha-kavach)
- [System Architecture](#-system-architecture)
- [Tech Stack](#-tech-stack)
- [Features](#-features)
- [Project Structure](#-project-structure)
- [Installation & Setup](#-installation--setup)
- [API Endpoints](#-api-endpoints)
- [Database Schema](#-database-schema)
- [Screenshots](#-screenshots)
- [Use Cases](#-use-cases)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🌟 Executive Summary

**Suraksha Kavach** (सुरक्षा कवच — *Safety Shield*) is a comprehensive **real-time fire safety monitoring and emergency response system** designed for multi-building residential complexes, commercial buildings, and industrial facilities.

It combines **IoT hardware sensors (ESP32)**, a **cross-platform mobile application (Flutter)**, a **professional web dashboard (Django)**, and **cloud services (Firebase)** into a unified safety ecosystem that detects fire hazards, alerts residents instantly, and coordinates emergency response — all within **10 seconds of detection**.

### 🏆 Key Metrics
| Metric | Value |
|--------|-------|
| 👥 Registered Users | 23+ |
| 📡 Active IoT Devices | 8+ |
| 📱 Push-enabled Users | 11+ |
| ⚡ Detection-to-Alert | < 10 seconds |
| 🔄 System Uptime | 100% |

---

## 🔥 Problem Statement

In multi-story residential and commercial buildings, fire incidents can escalate rapidly. Traditional fire safety systems suffer from:

- **Delayed Detection** — Manual detection relies on human observation
- **Slow Communication** — No instant notification to all building residents
- **No Centralized Monitoring** — Building managers lack real-time visibility
- **Fragmented Response** — No coordination between detection, alert, and response
- **Zero Audit Trail** — No records for compliance and improvement

> 💡 *Every minute of delay in fire response increases damage exponentially. Suraksha Kavach reduces response time from minutes to seconds.*

---

## 💡 The Solution — Suraksha Kavach

Suraksha Kavach acts as an intelligent **"Safety Shield"** that wraps around an entire building ecosystem:

```
Detection (The Sense)  →  Analysis (The Brain)  →  Response (The Shield)
      ESP32 Sensors     →    Django + Firebase    →    Mobile Alerts + Sprinklers
```

### How It Works

1. **🔍 Detection** — ESP32 IoT sensors continuously monitor temperature, gas levels, and flame presence across the building
2. **🧠 Analysis** — The Django backend calculates the "Instability Index" — if readings breach safe thresholds, the Kavach (Shield) is triggered
3. **🚨 Alert** — Firebase Cloud Messaging sends instant push notifications to all registered residents and safety personnel
4. **🛡️ Mitigation** — Automated sprinkler activation + emergency coordination through the dashboard
5. **📊 Audit** — Every incident, alert, and response is logged for compliance reporting

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     SURAKSHA KAVACH                          │
│               Fire Safety System v1.0                       │
└─────────────────────────────────────────────────────────────┘

┌────────────────┐        ┌──────────────┐        ┌──────────────┐
│   ESP32 IoT    │        │  Flutter App │        │ Web Dashboard│
│   Sensors      │        │  (Cross-OS)  │        │   (Django)   │
│                │        │              │        │              │
│ • Temperature  │        │ • Real-time  │        │ • Metrics    │
│ • Gas Detection│        │   alerts     │        │ • Analytics  │
│ • Flame Detect │        │ • Manual     │        │ • User Mgmt  │
│ • Sprinkler    │        │   trigger    │        │ • Reports    │
└────────┬───────┘        └──────┬───────┘        └──────┬───────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                        ┌────────▼────────┐
                        │  Firebase Cloud  │
                        │  ─────────────   │
                        │  • Firestore DB  │
                        │  • Auth          │
                        │  • FCM Push      │
                        │  • Realtime Sync │
                        └─────────────────┘
```

### Emergency Alert Flow

```
User/Sensor Triggers Alert
        │
        ▼
Backend creates Incident (INC-XXXXXXXX)
        │
        ├─▶ Alert record created (ALT-XXXXXXXX)
        ├─▶ AuditLog entry written
        │
        ▼
Fetch all users with FCM tokens
        │
        ▼
Firebase Cloud Messaging sends push notifications
        │
        ├─▶ Batch 1: Tokens 1-500
        ├─▶ Batch 2: Tokens 501-1000
        │
        ▼
📱 Users receive alert → Take action → Mark resolved
```

---

## 🛠️ Tech Stack

### Frontend — Mobile Application
| Technology | Purpose |
|------------|---------|
| **Flutter** (Dart) | Cross-platform mobile app (iOS & Android) |
| **Firebase Auth** | User authentication & session management |
| **Cloud Firestore** | Real-time data sync |
| **Firebase Cloud Messaging** | Push notifications |
| **SharedPreferences** | Local data caching |

### Backend — Web Dashboard & API
| Technology | Purpose |
|------------|---------|
| **Django 4.2** (Python) | REST API & web dashboard |
| **Django REST Framework** | API serialization & routing |
| **SQLite3** / PostgreSQL | Relational database |
| **Firebase Admin SDK** | Server-side Firebase integration |
| **Gunicorn** | Production WSGI server |

### Frontend — Web Dashboard
| Technology | Purpose |
|------------|---------|
| **HTML5 / CSS3** | Responsive glassmorphism UI |
| **Vanilla JavaScript** | Dynamic interactions |
| **Chart.js v4.4** | Real-time data visualization |
| **Font Awesome 6.4** | Icon system |
| **Google Fonts (Inter)** | Typography |

### Hardware — IoT Firmware
| Technology | Purpose |
|------------|---------|
| **ESP32** (Espressif) | Microcontroller |
| **DHT11/DHT22** | Temperature & humidity sensing |
| **MQ-5 / MQ-9** | Gas detection (LPG, CO) |
| **IR Flame Sensor** | Fire detection |
| **Relay Module** | Sprinkler activation |
| **WiFi 802.11 b/g/n** | Wireless connectivity |
| **Arduino IDE** | Firmware development |

---

## ✨ Features

### 🚨 One-Click Emergency Alert
Instantly notify **all building personnel** with a single button press. The system creates an incident record, sends FCM push notifications, and logs everything for audit compliance.

### 📊 Professional Real-Time Dashboard
- Live metrics (temperature, gas levels, flame status)
- 24-hour trend charts with Chart.js
- Active incident monitoring
- Personnel directory with roles
- Activity log and audit trail
- Glassmorphism UI with responsive design

### 📱 Cross-Platform Mobile App
- Real-time push notifications for fire/gas/emergency alerts
- Role-based dashboard views
- AI-powered safety assistant
- Device status monitoring
- Incident history and tracking
- Neighbour alert coordination

### 👥 Role-Based Access Control
| Role | Access Level |
|------|-------------|
| **Safety Officer** | Full system control, emergency triggers, user management |
| **Plant Manager** | System monitoring, staff management, analytics |
| **Supervisor** | Zone-specific monitoring and local controls |
| **Data Analyst** | Read-only analytics and report generation |
| **Resident** | Personal alerts, unit data, manual emergency trigger |

### 📡 IoT Device Management
- Real-time device online/offline status
- Sensor reading visualization
- Auto-discovery of new devices
- Remote sprinkler control and device testing

### 🔗 Firebase Cloud Integration
- Real-time data synchronization across all clients
- Secure user authentication
- Push notification delivery engine
- Firestore composite indexing for performance

### 📋 Compliance & Audit Trail
- Complete activity logging (who, what, when, where)
- Incident lifecycle tracking
- Alert delivery confirmation
- Exportable compliance reports

---

## 📁 Project Structure

```
Suraksha-Kavach/
│
├── 📱 fireguard_ai/                    # Flutter Mobile Application
│   ├── lib/
│   │   ├── main.dart                   # App entry point
│   │   ├── home_screen.dart            # Main navigation
│   │   ├── welcome_screen.dart         # Onboarding
│   │   ├── firebase_options.dart       # Firebase config
│   │   ├── core/                       # Core utilities & theme
│   │   ├── pages/                      # App screens
│   │   │   ├── dashboard_screen.dart   # Real-time dashboard
│   │   │   ├── ai_assistance_screen.dart # AI safety assistant
│   │   │   ├── alert_notifications_screen.dart
│   │   │   ├── device_status_screen.dart
│   │   │   ├── victim_alert_screen.dart
│   │   │   ├── neighbour_alert.dart
│   │   │   ├── safety_tips_screen.dart
│   │   │   ├── login.dart / register_screen.dart
│   │   │   ├── profile.dart
│   │   │   └── roles/                  # Role-based views
│   │   ├── services/                   # API & notification services
│   │   └── shared/                     # Shared widgets & constants
│   ├── assets/                         # Images, sounds, icons
│   ├── android/                        # Android platform config
│   ├── ios/                            # iOS platform config
│   ├── web/                            # Web platform config
│   ├── esp32_firmware/                 # Embedded ESP32 firmware
│   │   └── esp32_firmware.ino          # Arduino sketch
│   └── pubspec.yaml                    # Flutter dependencies
│
├── 🖥️ backend/                         # Django Backend & API
│   ├── manage.py                       # Django CLI
│   ├── requirements.txt                # Python dependencies
│   ├── config/                         # App configuration
│   ├── core/                           # Django project settings
│   │   ├── settings.py
│   │   ├── urls.py
│   │   └── wsgi.py
│   └── fireguard_ai/                   # Main Django app
│       ├── models.py                   # Database models
│       ├── views.py                    # API views & dashboard
│       ├── urls.py                     # URL routing
│       └── templates/                  # Dashboard HTML templates
│
├── ⚡ firmware/                         # Standalone ESP32 Firmware
│   └── esp32_fireguard/
│       └── esp32_fireguard.ino         # Production firmware
│
├── 📊 DASHBOARD_SETUP.py               # Dashboard initialization script
├── 📋 IMPLEMENTATION_SUMMARY.md         # Technical implementation notes
├── 🔥 firestore.indexes.json            # Firestore index definitions
├── 📖 README.md                         # This file
└── 🚫 .gitignore                        # Git ignore rules
```

---

## 📥 Installation & Setup

### Prerequisites
- **Flutter SDK** ≥ 3.10.4
- **Python** ≥ 3.11
- **Arduino IDE** (for ESP32 firmware)
- **Firebase Project** with Firestore, Auth, and FCM enabled
- **Git**

### 1. Clone the Repository
```bash
git clone https://github.com/heersd4114-art/Suraksha-Kavach.git
cd Suraksha-Kavach
```

### 2. Backend Setup (Django)
```bash
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run migrations
python manage.py migrate

# Start the server
python manage.py runserver 0.0.0.0:8000
```

### 3. Mobile App Setup (Flutter)
```bash
cd fireguard_ai

# Get dependencies
flutter pub get

# Run on connected device
flutter run

# Build APK
flutter build apk --release
```

### 4. ESP32 Firmware Setup
1. Open `firmware/esp32_fireguard/esp32_fireguard.ino` in **Arduino IDE**
2. Install required libraries: `WiFi`, `HTTPClient`, `DHT`, `ArduinoJson`
3. Configure WiFi credentials and server IP in the firmware
4. Select **ESP32 Dev Module** as board
5. Upload to ESP32

### 5. Firebase Configuration
1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication**, **Cloud Firestore**, and **Cloud Messaging**
3. Download and place `google-services.json` in `fireguard_ai/android/app/`
4. Download Firebase Admin SDK key for the backend

---

## 🔌 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/emergency-alert/` | Trigger emergency alert to all users |
| `GET` | `/api/dashboard-data/` | Fetch real-time dashboard metrics |
| `GET` | `/api/designation-access/` | Get user permissions & access level |
| `GET` | `/api/users/` | List all active users |
| `POST` | `/api/broadcast-alert/` | Send targeted alert to specific users |
| `POST` | `/api/update-device/` | Update device status |
| `GET` | `/api/test/` | Test Firebase connectivity |
| `GET` | `/api/professional-dashboard/` | Web dashboard UI |

> **Authentication**: All API endpoints require the `X-User-ID` header with a valid Firebase UID.

---

## 🗄️ Database Schema

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  UserProfile │     │    Device    │     │   LiveData   │
│──────────────│     │──────────────│     │──────────────│
│ uid          │◄────│ owner (FK)   │────►│ device (1:1) │
│ name         │     │ device_id    │     │ temperature  │
│ email        │     │ building_id  │     │ gas_level    │
│ phone        │     │ block        │     │ flame_detected│
│ role         │     │ house        │     │ sprinkler    │
│ designation  │     │ status       │     │ updated_at   │
│ fcm_token    │     │ installed_at │     └──────────────┘
│ building_id  │     └──────────────┘
│ block        │
│ house        │     ┌──────────────┐     ┌──────────────┐
│ is_active    │     │   Incident   │     │    Alert     │
└──────────────┘     │──────────────│     │──────────────│
                     │ incident_id  │◄────│ incident(FK) │
┌──────────────┐     │ device (FK)  │     │ user (FK)    │
│  AuditLog    │     │ type         │     │ priority     │
│──────────────│     │ severity     │     │ status       │
│ actor (FK)   │     │ status       │     │ time         │
│ action       │     │ created_at   │     └──────────────┘
│ target_id    │     └──────────────┘
│ target_type  │
│ metadata     │     ┌──────────────┐     ┌──────────────┐
│ created_at   │     │ BlockManager │     │  Authority   │
└──────────────┘     │──────────────│     │──────────────│
                     │ building_id  │     │ building_id  │
┌──────────────┐     │ block        │     │ role         │
│  BlockIndex  │     │ name         │     │ name         │
│──────────────│     │ phone        │     │ phone        │
│ building_id  │     │ user (1:1)   │     │ user (1:1)   │
│ block        │     └──────────────┘     └──────────────┘
│ house        │
│ user (FK)    │     ┌──────────────┐
└──────────────┘     │FireDepartment│
                     │──────────────│
                     │ building_id  │
                     │ station_name │
                     │ phone        │
                     │ station_id   │
                     └──────────────┘
```

---

## 🎯 Use Cases

| Scenario | How Suraksha Kavach Helps |
|----------|--------------------------|
| 🏠 **Residential Fire** | ESP32 detects flame → Instant push to all residents → Sprinkler auto-activates |
| 💨 **Gas Leak** | MQ sensor detects elevated PPM → Alert with evacuation instructions |
| 🏭 **Industrial Safety** | 24/7 monitoring with compliance audit trail |
| 🚁 **Emergency Coordination** | One-click alert to fire department + all personnel |
| 📊 **Building Management** | Real-time dashboard for safety officers |

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Suraksha Kavach Team**
- Project Type: Enterprise IoT Fire Safety Management System
- Category: Anti-Gravity Security / Safety System
- Status: ✅ Active & Operational

---

<p align="center">
  <strong>🛡️ Suraksha Kavach — Because Every Second Counts in Fire Safety 🔥</strong>
</p>
