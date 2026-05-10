# ECon — Energy Control

<p align="center">
  <img src="assets/logo.png" alt="ECon Logo" width="150"/>
</p>

<p align="center">
  <strong>Smart Energy Monitoring, Anomaly Detection & Regional Load Management</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-SDK-blue?logo=flutter" />
  <img src="https://img.shields.io/badge/Dart-3.9.2+-blue?logo=dart" />
  <img src="https://img.shields.io/badge/Firebase-Realtime%20DB-orange?logo=firebase" />
  <img src="https://img.shields.io/badge/Platform-Android-green?logo=android" />
  <img src="https://img.shields.io/badge/Version-1.0.0-brightgreen" />
</p>

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Screens & Pages](#screens--pages)
- [Firebase Database Schema](#firebase-database-schema)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Admin Panel](#admin-panel)
- [AI & Anomaly Detection](#ai--anomaly-detection)
- [PDF Reports](#pdf-reports)
- [Billing Analysis](#billing-analysis)
- [Regional Load Control](#regional-load-control)
- [Device Inventory](#device-inventory)
- [Utility Integration](#utility-integration)
- [Automation](#automation)
- [Notifications](#notifications)
- [Security Notes](#security-notes)
- [Known Issues & Limitations](#known-issues--limitations)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

**ECon (Energy Control)** is a cross-platform Flutter mobile application designed for smart energy monitoring and management. It connects to IoT energy meters via Firebase Realtime Database and provides:

- **Real-time** voltage, current, power, and energy unit tracking
- **AI-powered** anomaly and theft detection with smart alert levels
- **Admin panel** for user management, device inventory, and regional load control
- **PDF reports** and billing trend visualization
- **Automation rules** for demand response management
- **Utility provider integration** with comprehensive tariff configuration

The system follows a two-tier model: **Admins** manage the overall infrastructure and user accounts, while **Users** monitor their own energy consumption and manage their assigned smart meter.

---

## Features

### For Users
| Feature | Description |
|---|---|
| Real-time Monitoring | Live voltage (V), current (A), power (W), and energy units (kWh) |
| Billing Tracker | Auto-calculated bill in PKR (Rs) |
| Load Control | Toggle three independent loads + overall master switch |
| AI Alerts | Anomaly and theft detection with 4 alert levels |
| PDF Reports | Generate and share dated energy reports |
| Billing Analysis | Historical billing trends with interactive line chart |
| Automation | Configure demand-response rules and power thresholds |
| Utility Integration | Store utility provider details and tariff settings |

### For Admins
| Feature | Description |
|---|---|
| User Management | View all users, inspect consumption, delete accounts |
| Create Users | Register new users with device assignment |
| Region Control | Mass-toggle loads for entire countries/cities |
| Device Inventory | Add, track, and manage ECon smart meter devices |
| Consumption Table | Horizontal scrolling table of all users' live data |

---

## Tech Stack

### Framework
- **Flutter** (stable channel)
- **Dart SDK** `^3.9.2`

### Backend & Database
- **Firebase Core** — Firebase initialization
- **Firebase Authentication** — Email & password auth
- **Firebase Realtime Database** — Live sensor data, user profiles, inventory

### UI & Visualization
- **fl_chart** — Interactive line charts for billing trends
- **Material Design** — Primary UI framework
- **Cupertino Icons** `^1.0.8` — iOS-style icon set

### Utilities
- **intl** — Date formatting & internationalization
- **shared_preferences** — Local app preferences (onboarding state)
- **flutter_local_notifications** — Push notifications for AI alerts
- **http** — HTTP client (reserved for future API integrations)

### Reporting
- **pdf** — PDF document generation
- **printing** — Native share/download for generated PDFs

### Code Quality
- **flutter_lints** `^5.0.0` — Lint rules following Flutter best practices

---

## Project Structure

```
energycontrol/
├── lib/
│   ├── main.dart                      # App entry, Firebase init, notification setup
│   ├── SplashScreen.dart              # 2s splash with onboarding check
│   ├── OnboardingScreen.dart          # 4-page onboarding carousel
│   ├── HomePage.dart                  # Landing page (User / Admin entry)
│   │
│   ├── ── Authentication ──
│   ├── LoginPage.dart                 # User email/password login
│   ├── SignupPage.dart                # New user registration (admin-only)
│   ├── AdminLoginPage.dart            # Admin credential login
│   │
│   ├── ── Admin ──
│   ├── admindashboard.dart            # Admin dashboard + UserListPage
│   ├── regioncontrol.dart             # Regional mass load control
│   ├── inventory.dart                 # Device inventory management
│   ├── consumptiondetails.dart        # All-user consumption table
│   │
│   ├── ── User ──
│   ├── Dashboard.dart                 # Main user dashboard (real-time data + alerts)
│   ├── dashboard2.dart                # Alternate dashboard version
│   ├── ReportsPage.dart               # PDF report generation
│   ├── BillingAnalysisPage.dart       # Billing trends & chart
│   ├── AutomationPage.dart            # Demand response automation settings
│   ├── UtilityIntegrationPage.dart    # Utility provider & tariff config
│   │
│   ├── ── Misc ──
│   ├── SuggestionsDialog.dart         # AI suggestions dialog
│   ├── PatientDetailsPage.dart        # Unused legacy page
│   └── firebase_options.dart          # Firebase configuration (auto-generated)
│
├── assets/
│   └── logo.png                       # App logo
│
├── android/                           # Android native project
│   └── app/src/main/
│       ├── res/                       # Android resources (icons, colors)
│       └── google-services.json       # Firebase Android config
│
├── ios/                               # iOS native project
├── web/                               # Web build artifacts
├── pubspec.yaml                       # Dependencies & asset declarations
└── analysis_options.yaml              # Lint configuration
```

---

## Screens & Pages

### Splash Screen
- Displays the ECon logo for 2 seconds
- Reads `seenOnboarding` key from `SharedPreferences`
- Routes to **OnboardingScreen** (first launch) or **HomePage** (returning users)

---

### Onboarding Screen
- 4-page `PageView` carousel:
  1. **Welcome** — Introduction to ECon
  2. **Monitor Energy** — Explain real-time tracking
  3. **Save Bills** — Highlight billing features
  4. **Get Started** — Final call to action
- Dot indicators track current page
- Saves `seenOnboarding = true` to `SharedPreferences` on completion
- Routes to **LoginPage**

---

### Home Page
- ECon branding with tagline
- Two action buttons:
  - `USER LOGIN` → LoginPage
  - `ADMIN` → AdminLoginPage

---

### Login Page
- Fields: Email, Password (with visibility toggle)
- Forgot Password — sends Firebase email reset
- Email sanitization: dots replaced with underscores for database node lookup  
  e.g., `user@gmail.com` → node key `user@gmail_com`
- Verifies user exists in Firebase Realtime Database before granting access
- Routes to **Dashboard** on success

---

### Signup Page *(Admin only)*
- Fields: Name, Email, Password, Country, City, Device Selection
- **Country dropdown:** Pakistan, Bangladesh, Afghanistan, Saudi Arabia, UAE, Turkey, Indonesia, Malaysia, Egypt, Morocco
- **City dropdown:** Dynamically populated based on selected country (20–40 cities each)
- **Device dropdown:** Fetches only `inactive` devices from inventory
- On submit:
  - Creates user node in Firebase under sanitized email key
  - Sets selected device status to `active`
- Routes back to AdminDashboard

---

### Admin Login Page
- Fields: Username, Password
- **Hardcoded credentials:** `admin` / `1234` *(see [Security Notes](#security-notes))*
- Routes to **AdminDashboardPage**

---

### Admin Dashboard
A 5-card grid menu:

| Card | Routes To |
|---|---|
| User Data | UserListPage |
| Create User | SignupPage |
| Region Control | RegionControlPage |
| Inventory | InventoryPage |
| Details | ConsumptionDetailsPage |

**UserListPage** (nested in `admindashboard.dart`):
- StreamBuilder showing all users (filtered by `@gmail_com` nodes)
- Tap user to view their Dashboard
- Delete user with confirmation → removes user node + marks device inactive

---

### Dashboard *(Main User Screen)*
Real-time stat cards:
- **Voltage (V)** — measured in Volts
- **Current (A)** — measured in Amperes
- **Power (W)** — measured in Watts
- **Units (kWh)** — cumulative energy consumed
- **Bill (Rs)** — calculated bill in Pakistani Rupees

Load control toggle switches:
- Primary Load
- Secondary Load 1
- Secondary Load 2
- Overall Master Switch

Navigation buttons: Suggestions | Reports | Billing | Automation | Utility

AI alert banner with anomaly/theft score indicators  
Logout button

---

### Reports Page
- Select date range (From / To)
- Generate PDF containing:
  - User name, email, date range
  - Current sensor readings
  - AI analysis results (scores, alert level, reason)
  - Suggestions and action items
- Share or download via native share sheet

---

### Billing Analysis Page
- Loads `billing_history` node from Firebase
- Summary cards: Total Bill, Total Units, Average Bill, Average Units
- Interactive line chart (via `fl_chart`) showing bill trends over time
- Dynamically updates as new billing data arrives

---

### Automation Page
Demand-response automation settings saved to Firebase:

| Setting | Type | Description |
|---|---|---|
| Auto Mode | Toggle | Enable automated load control |
| Peak Saving Mode | Toggle | Reduce usage during peak hours |
| Allow Load 1 Auto Control | Toggle | Let system manage Load 1 |
| Allow Load 2 Auto Control | Toggle | Let system manage Load 2 |
| Allow Load 3 Auto Control | Toggle | Let system manage Load 3 |
| Max Power Threshold | Number | Max allowed power in Watts |
| Max Bill Threshold | Number | Max allowed bill in Rs |

---

### Utility Integration Page
14+ fields organized into sections:

**Utility Provider**
- Company Name, Provider Code, Customer Name, Region

**Meter & Account**
- Meter Number, Account Number
- Billing Cycle: Monthly / Bi-Monthly / Quarterly
- Tariff Type: Residential / Commercial / Industrial / Time-of-Use

**Tariff Settings**
- Base Tariff, Peak Tariff, Off-Peak Tariff (Rs/kWh)
- Monthly Limit (kWh)

**Peak Hours & Demand Response**
- Peak Start/End Time
- Enable Demand Response (toggle)
- Auto Disconnect on Threshold (toggle)

**Additional**
- Notes (free-text)
- Remote Utility Command (toggle — placeholder for future API)
- Utility Alerts (toggle)

Data saved to Firebase with server-side timestamp.

---

### Region Control Page *(Admin)*
- Country and City dropdowns (same lists as Signup)
- Four regional toggle switches:
  - Primary Load, Secondary Load 1, Secondary Load 2, Overall Control
- Iterates through all Firebase user nodes matching selected region
- Updates load states for every matching user simultaneously
- Success/error SnackBar feedback

---

### Inventory Page *(Admin)*
- Auto-incrementing device IDs in format `ECO-00001`
- Add device form: Manufacturing Date, Device Type (Domestic / Industrial)
- 2-column grid display of all devices
- Color-coded status badge: green = active, red = inactive
- Delete only available for inactive devices
- Real-time StreamBuilder updates

---

### Consumption Details Page *(Admin)*
- Horizontally scrollable data table
- Columns: Name | Power (W) | Units (kWh) | Current (A) | Bill (Rs)
- Streams live data for all registered users

---

## Firebase Database Schema

```
/ (Realtime Database root)
│
├── [sanitized-email]/                    e.g., user@gmail_com
│   ├── name                              (String)
│   ├── email                             (String)
│   ├── country                           (String)
│   ├── city                              (String)
│   ├── device_id                         (String)  e.g., "ECO-00001"
│   │
│   ├── voltage                           (double)
│   ├── current                           (double)
│   ├── power                             (double)
│   ├── units                             (double)  kWh
│   ├── bill                              (double)  Rs
│   │
│   ├── load1                             (bool)    Primary Load
│   ├── load2                             (bool)    Secondary Load 1
│   ├── load3                             (bool)    Secondary Load 2
│   ├── overall                           (bool)    Master Switch
│   │
│   ├── suggestion/
│   │   ├── anomaly_score                 (double)  0.0 – 1.0
│   │   ├── theft_score                   (double)  0.0 – 1.0
│   │   ├── status                        (String)
│   │   ├── reason                        (String)
│   │   ├── suggestion                    (String)
│   │   ├── alert_level                   (String)
│   │   ├── action_items                  (List/Map)
│   │   ├── tariff                        (Map)
│   │   └── updated_at                    (timestamp)
│   │
│   ├── automation/
│   │   ├── auto_mode                     (bool)
│   │   ├── peak_saving_mode              (bool)
│   │   ├── allow_load1_auto              (bool)
│   │   ├── allow_load2_auto              (bool)
│   │   ├── allow_load3_auto              (bool)
│   │   ├── max_power_threshold           (double)
│   │   └── max_bill_threshold            (double)
│   │
│   ├── utility_integration/
│   │   ├── company_name
│   │   ├── provider_code
│   │   ├── customer_name
│   │   ├── region
│   │   ├── meter_number
│   │   ├── account_number
│   │   ├── billing_cycle
│   │   ├── tariff_type
│   │   ├── base_tariff
│   │   ├── peak_tariff
│   │   ├── offpeak_tariff
│   │   ├── monthly_limit
│   │   ├── peak_start
│   │   ├── peak_end
│   │   ├── demand_response_enabled       (bool)
│   │   ├── auto_disconnect               (bool)
│   │   ├── remote_command_enabled        (bool)
│   │   ├── utility_alerts_enabled        (bool)
│   │   ├── notes
│   │   └── updated_at                    (ServerValue.timestamp)
│   │
│   ├── billing_history/
│   │   └── [entry]/
│   │       ├── bill                      (double)
│   │       ├── units                     (double)
│   │       └── date                      (String)
│   │
│   └── ai_result/                        (AI analysis output)
│
└── inventory/
    └── [device-id]/                      e.g., ECO-00001
        ├── manufactured_date             (String)
        ├── type                          (String)  Domestic / Industrial
        └── status                        (String)  active / inactive
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (stable channel)
- Dart `3.9.2` or higher
- Android Studio or VS Code with Flutter extension
- A physical Android device or emulator (API 21+)
- Firebase project access (credentials already in `firebase_options.dart`)

### Installation

**1. Clone the repository**
```bash
git clone https://github.com/<your-username>/energycontrol.git
cd energycontrol
```

**2. Install Flutter dependencies**
```bash
flutter pub get
```

**3. Verify Flutter setup**
```bash
flutter doctor
```

**4. Place Firebase configuration file**

Ensure `android/app/google-services.json` is present. This file is tied to Firebase project `ecot-5cebb`.

**5. Run the app**
```bash
flutter run                   # auto-detects connected device
flutter run -d android        # explicit Android
flutter run -d <device-id>    # specific device
```

**6. Build release APK**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### First-Time Usage Flow

```
App Launch
  └─ SplashScreen (2s)
       ├─ First launch  → OnboardingScreen (4 pages) → HomePage
       └─ Returning     → HomePage
                              ├─ USER LOGIN → LoginPage → Dashboard
                              └─ ADMIN      → AdminLoginPage → AdminDashboard
```

> **Note:** Regular users cannot self-register. An admin must create their account via **Admin Dashboard → Create User**.

---

## Configuration

### Firebase

The app is pre-configured for Firebase project `ecot-5cebb`. Key details:

| Setting | Value |
|---|---|
| Project ID | `ecot-5cebb` |
| Realtime DB URL | `https://ecot-5cebb-default-rtdb.asia-southeast1.firebasedatabase.app` |
| Storage Bucket | `ecot-5cebb.firebasestorage.app` |
| Region | Asia Southeast 1 |

To use your own Firebase project:

1. Create a new Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication** (Email/Password) and **Realtime Database**
3. Run `flutterfire configure` to regenerate `firebase_options.dart`
4. Replace `android/app/google-services.json`

### Notification Channel

Configured in `main.dart`:
```
Channel ID:   ecot_alerts
Channel Name: E-Cot Alerts
Sound:        Enabled
```

### Onboarding Preference Key

```
SharedPreferences key: seenOnboarding (bool)
```

---

## Admin Panel

### Accessing Admin
Navigate to: **Home → ADMIN → enter credentials**

Default credentials *(change before production)*:
```
Username: admin
Password: 1234
```

### Admin Capabilities

1. **User Data** — Browse all users, tap to view their live dashboard, delete accounts (cascades to device deactivation)
2. **Create User** — Register a new user, select their country/city and assign an inactive device
3. **Region Control** — Bulk-toggle loads for all users in a specific country + city combination
4. **Inventory** — Add smart meter devices with manufacturing date and type; track active/inactive status
5. **Details** — Live scrollable table of all users' power, units, current, and bill

---

## AI & Anomaly Detection

The app reads AI analysis results from the `suggestion/` node in the user's Firebase record. These values are typically written by a separate backend ML service.

### Scores
| Field | Range | Meaning |
|---|---|---|
| `anomaly_score` | 0.0 – 1.0 | Probability of abnormal energy pattern |
| `theft_score` | 0.0 – 1.0 | Probability of energy theft |

### Alert Levels

| Level | Trigger Condition | UI Response |
|---|---|---|
| **Normal** | Both scores = 0.0 | Green indicator, no alert |
| **Info** | Any score > 0.0 | Blue SnackBar |
| **Warning** | theft_score >= 0.45 OR anomaly_score >= 0.50 | Orange SnackBar + notification |
| **Critical** | theft_score >= 0.70 | Red alert dialog + loud notification |

### AI Output Fields Used
- `reason` — Human-readable explanation of the detected pattern
- `suggestion` — Recommended action for the user
- `action_items` — List of specific steps to resolve the alert
- `tariff` — Current tariff information from AI analysis
- `updated_at` — Timestamp of last AI analysis

---

## PDF Reports

Generated from **Dashboard → Reports**:

- **Content:** User info, date range, current readings, AI scores, alert level, suggestions, action items
- **Format:** PDF with ECon branding
- **Share:** Native OS share sheet (email, WhatsApp, Drive, etc.)
- **Download:** Save directly to device storage

Powered by the `pdf` and `printing` packages.

---

## Billing Analysis

Accessed from **Dashboard → Billing**:

- Reads `billing_history/` node from Firebase
- **Summary cards:** Total Bill | Total Units | Average Bill | Average Units
- **Line chart** (via `fl_chart`): Bills plotted chronologically
- Updates in real-time as backend writes new billing records

---

## Regional Load Control

Admin feature for mass operations:

1. Select **Country** from dropdown
2. Select **City** from dropdown
3. Toggle desired loads (Primary / Secondary 1 / Secondary 2 / Overall)
4. App iterates through all Firebase users matching country + city
5. Updates load fields for every matched user simultaneously

> Suitable for deployments up to ~10,000 users. For larger fleets, consider Firebase Cloud Functions for batch writes.

---

## Device Inventory

Admins manage ECon smart meters at **Admin Dashboard → Inventory**:

- **Auto ID generation:** Scans existing IDs and increments (`ECO-00001`, `ECO-00002`, ...)
- **Device fields:** Manufactured date, Type (Domestic / Industrial), Status
- **Status lifecycle:** `inactive` (unassigned) → `active` (assigned to user) → `inactive` (user deleted)
- Only `inactive` devices can be deleted from inventory
- Assigned via Signup page (only inactive devices shown in dropdown)

---

## Utility Integration

A comprehensive form for storing utility provider details. Accessible from **Dashboard → Utility**.

Supports:
- **Billing cycles:** Monthly, Bi-Monthly, Quarterly
- **Tariff types:** Residential, Commercial, Industrial, Time-of-Use
- **Peak pricing:** Separate base, peak, and off-peak rates
- **Demand response:** Peak window times and auto-disconnect rules
- **Future-ready:** Remote command toggle placeholder for direct utility API

All data persisted to `utility_integration/` node with `ServerValue.timestamp`.

---

## Automation

Configure demand-response rules at **Dashboard → Automation**:

- **Auto Mode** — Enables all automated load decisions
- **Peak Saving Mode** — Reduces active loads during peak hours
- **Per-load auto control** — Fine-grained control over Load 1, 2, and 3
- **Power threshold (W)** — System will shed load if power exceeds this value
- **Bill threshold (Rs)** — System will shed load if projected bill exceeds this value

Settings persisted to `automation/` node in Firebase.

---

## Notifications

Local push notifications are triggered by the AI alert system:

| Scenario | Notification Type |
|---|---|
| Warning level detected | Silent notification + SnackBar |
| Critical / theft detected | Loud notification + alert dialog |

Notification channel: `ecot_alerts`  
Android permissions: Configured in `AndroidManifest.xml`  
Initialization: `AndroidInitializationSettings` in `main.dart`

---

## Security Notes

> These issues should be resolved before any production deployment.

1. **Hardcoded admin credentials** — `admin` / `1234` in `AdminLoginPage.dart`. Move to Firebase Authentication or a secure backend.

2. **Firebase API key exposed** — `firebase_options.dart` contains the Firebase Web API key. Restrict the key in [Google Cloud Console](https://console.cloud.google.com) to specific Android package names and SHA certificates.

3. **Firebase Realtime Database rules** — Ensure rules are not set to open read/write. Implement proper user-scoped rules:
   ```json
   {
     "rules": {
       "$uid": {
         ".read": "$uid === auth.uid",
         ".write": "$uid === auth.uid"
       },
       "inventory": {
         ".read": "auth !== null",
         ".write": "auth !== null"
       }
     }
   }
   ```

4. **Email sanitization** — The dot-to-underscore convention for database keys is functional but non-standard. This works correctly as long as it is applied consistently across all auth and admin features.

---

## Known Issues & Limitations

| Issue | Detail |
|---|---|
| iOS not configured | `firebase_options.dart` only has Android config. iOS requires separate FlutterFire setup. |
| Hardcoded admin credentials | See Security Notes above |
| `PatientDetailsPage.dart` | Legacy unused file from a previous project; can be safely deleted |
| `http` package unused | Imported but no active HTTP calls in UI code — reserved for future integrations |
| Region control scale | Iterates all users client-side; may be slow for large user bases |

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit changes: `git commit -m "Add your feature"`
4. Push to branch: `git push origin feature/your-feature`
5. Open a Pull Request

Please follow the existing code style and run `flutter analyze` before submitting.

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

<p align="center">
  Built with Flutter &amp; Firebase &nbsp;|&nbsp; ECon &copy; 2024
</p>
