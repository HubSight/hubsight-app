# HubSight Mobile App

<p align="center">
  <b>Smart CCTV Surveillance, AI Event Playback & Security Management for Mobile</b>
</p>

---

## Overview

**HubSight Mobile** is the mobile client for the HubSight CCTV & AI Smart Surveillance platform, built with **Flutter**, **Riverpod**, **WebRTC**, and **Socket.IO**. It enables live camera monitoring, AI event timeline playback, instant security alerts, device management, and secure system settings on iOS and Android devices.

---

## Key Features

- **Dynamic Server URL Configuration**:
  - Prompted on first launch to configure the API Gateway address.
  - Persisted locally with `SharedPreferences`.
  - Can be tested with real-time connectivity feedback and changed at any time from Login or Settings.
- **Low-latency WebRTC Live Streaming**:
  - Ultra-low-latency video streaming powered by `flutter_webrtc` and `go2rtc`.
  - Automatic WHEP SDP negotiation and 15-second heartbeat mechanism to keep connection pool slots alive.
- **24-Hour AI Event Timeline & Playback**:
  - Daily event-based playback with visual 24h event markers (`danger`, `fall`, `stranger`, `motion`).
  - Period filtering (`00-12h`, `12-18h`, `18-24h`) and interactive recording segments.
- **Real-time Notifications & Alerts**:
  - Socket.IO client streaming real-time alerts (`notification.new`) and camera lifecycle events (`camera.stopped`, `camera.started`, `camera.updated`).
  - Filter tabs (`All`, `Unread`), single/bulk read, and delete actions.
- **Navigation & User Profile Popover**:
  - Clean sidebar navigation drawer.
  - Floating profile popover menu with quick access to Settings, Change Password, and Logout.
- **Account & Security Settings**:
  - Modal dialog for changing passwords with validation.
  - Push notification categories (`Family`, `Security & Strangers`, `System`).
  - Display timezone picker (`UTC+7`, `UTC+8`, `UTC+9`, `UTC+0`, `UTC-5`, `UTC-8`).
  - App background lock & biometric unlock timeout settings.
- **Internationalization (i18n)**:
  - Full multi-language support for **Tiếng Việt (`vi`)** and **English (`en`)** via `.arb` dictionaries.

---

## Project Structure

```text
lib/
├── core/
│   ├── models/            # Data models (Auth, Devices, Members, NVR, Pool)
│   ├── network/
│   │   ├── api_client.dart       # Dio REST API Client (Auth, Cameras, Archive, Members, NVR, Pool)
│   │   └── socket_service.dart   # Socket.IO Real-time Relay Service
│   └── storage/
│       └── storage_service.dart  # SharedPreferences persistence (Server URL, Auth Token, Profile)
├── features/
│   ├── auth/              # Login Screen, Change Password Modal
│   ├── camera/            # Playback Screen, WebRTC Viewer, Camera Models
│   ├── common/            # App Sidebar Drawer & User Popover Menu
│   ├── config/            # First-launch Server URL Setup Screen
│   ├── notifications/     # Notifications List & Alert Cards
│   └── settings/          # Device & Security Settings Screen
├── l10n/
│   ├── app_en.arb         # English translation dictionary
│   └── app_vi.arb         # Vietnamese translation dictionary
└── main.dart              # Entrypoint, Riverpod ProviderScope, Startup Router
```

---

## Backend Microservices Integration

The mobile app connects to the **HubSight API Gateway** (default port `:8088`), which proxies requests to the underlying microservices:

| Route Path | Microservice | Purpose |
| :--- | :--- | :--- |
| `/api/auth/*` | `auth-service:8081` | Authentication, Profile, Password, Locale & Preferences |
| `/api/*` | `core-service:8080` | Cameras, Archive, Playback Timeline, Members, NVR settings |
| `/relay/*` | `relay-service:3001` | Socket.IO real-time event distribution |
| `/api/live/:id/webrtc` | `pool-service` / `go2rtc` | WHEP WebRTC SDP offer/answer streaming |
| `/api/live/:id/heartbeat`| `pool-service` | Stream lease keep-alive ping |

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (`>= 3.20.0`)
- Android Studio / Xcode for emulators or physical device deployment

### Installation & Run

1. **Clone the repository**:
   ```bash
   git clone <repo-url>
   cd cctv-app
   ```

2. **Generate platform scaffolding** (if initializing fresh):
   ```bash
   flutter create .
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run code generation (for localization)**:
   ```bash
   flutter gen-l10n
   ```

5. **Start the application**:
   ```bash
   flutter run
   ```

---

## Server Configuration

- **Android Emulator**: Use `http://10.0.2.2:8088` to reach the gateway running on the host machine.
- **iOS Simulator**: Use `http://localhost:8088`.
- **Physical Devices**: Use your host machine's LAN IP (e.g. `http://192.168.1.100:8088`) or public domain.

You will be prompted to enter and test this URL on the first application launch, and you can update it at any time from the **Login Screen** or **Settings**.

---

## License & Credits

- **Author**: Anh Quoc Tran
- **Copyright**: © 2026 HubSight
