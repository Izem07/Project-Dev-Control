# 🎛️ ScoutOps Admin Menu — Dev Control

ScoutOps Admin Menu is the central dev control station for the ScoutOps scouting system. It is an Electron-based desktop application that lets admins launch, monitor, and manage all ScoutOps sub-applications from a single hub — without touching the terminal.

## 🔍 General Information

- **App Name:** ScoutOps Admin Menu
- **Primary Purpose:** Unified Dev Control for all ScoutOps services — server, web apps, mobile builds, and live log streaming.
- **Intended Users:** Scouting admins and dev leads for FRC Team 201 The FEDS.
- **Platforms Supported:** Windows (primary), macOS and Linux (Electron cross-platform capable).

## ✨ Features

- **App Control Panel** — Start, stop, and monitor all ScoutOps sub-apps with one click.
- **Live Dev Logs** — Real-time stdout/stderr streaming from every running process.
- **Merged Workspace** — Embed running web apps directly inside the control panel via iframe.
- **Server Health** — Monitor connected scouting devices, sync status, and data records.
- **Server Sync** — Set server IP/port for tablet connectivity.
- **Android Build** — One-click APK compilation for field Android tablets.
- **iOS Build** — One-click IPA compilation for iPads and iPhones (requires macOS for signing).
- **Settings** — Customize ports, launch commands, and working directories for all sub-apps.

## 🛠️ Sub-Applications Managed

| App ID    | Name                    | Default Port | Technology  |
|-----------|-------------------------|-------------|-------------|
| server    | Scout Ops Server        | 5000        | Python      |
| lookup    | Scout Lookup            | 3000        | Next.js     |
| dash      | Scout Analytics         | 8080        | Flutter Web |
| viewer    | Match Viewer            | 8081        | Flutter Web |
| scan      | Scout Ops Scan          | 8082        | Flutter Web |
| android   | Scout Ops Android       | —           | Flutter APK |
| ios       | Scout Ops iOS           | —           | Flutter IPA |

## 🚀 Setup and Usage

### Prerequisites

- Node.js v20+
- npm
- Electron (installed via npm)

### Install & Run

```bash
cd scouting/dev-control
npm install
npm start
```

### Build (Windows)

```bash
npm run build
```

Output goes to `winx64/`.

### iOS Build Note

The iOS IPA build (`flutter build ipa`) must be run on **macOS with Xcode** installed for proper code signing and device deployment. The Admin Menu will trigger the command, but signing and distribution require a Mac environment.

## 🛠️ Technical Stack

- **Electron** — Cross-platform desktop shell
- **electron-store** — Persistent config storage
- **Vanilla JS + CSS** — No frontend framework, keeps bundle minimal
- **IPC (contextBridge)** — Secure renderer ↔ main process communication

## 🐛 Known Issues

- iOS IPA build from Windows will compile but cannot be signed without macOS/Xcode.
- Embedded iframe view requires the target app to be running and accessible on localhost.
