# 🤖 Scout-Ops Suite

**Scout-Ops Suite** is a centralized FRC scouting platform designed to **store, manage, and unify every Scout-Ops app** used by a team. It serves as the backbone of the Scout-Ops ecosystem, keeping scouting data organized, accessible, and competition-ready.

Built **by FRC students, for FRC teams**, Scout-Ops Suite prioritizes reliability, speed, and scalability in high-pressure competition environments.

---

## 🚀 Features

- 📦 **One Download, Multiple Tools**  
  Single mobile app with built-in modules for match scouting, pit scouting, and QR scanning—no App Store chaos at competitions.

- 📊 **Unified Scouting Data**  
  Aggregates data from all scouting modules into a single, coherent system.

- ⚡ **Competition-Ready Performance**  
  Designed to work reliably with limited or no internet access.

- 🔄 **Seamless Module Integration**  
  Flip between match scouting, pit scouting, and QR scanning with a single tap.

- 🧠 **Data-Driven Insights**  
  Enables faster analysis and smarter strategic decisions.

---

## 🛠️ Purpose

Scout-Ops Suite solves a common FRC challenge:

> Too many scouting apps, too many data formats, and not enough time.

By acting as a **central hub**, Scout-Ops Suite ensures:
- Scouting data stays consistent
- Apps work together instead of separately
- Teams focus on strategy, not troubleshooting

---

## 🧩 Architecture Overview

```
[ SCOUT-OPS SUITE ]
       │
       ├───► [ Dev Control Hub ] ◄─── CENTRAL ORCHESTRATOR
       │         │
       │         ├── Controls & monitors all sub-apps
       │         ├── Live log streaming from all services
       │         ├── One-click Android/iOS builds
       │         └── Embedded web apps (server, dash, viewer, scan)
       │
       ├───► [ Mobile App (iOS / Android) ] ◄─── (ONE SINGLE DOWNLOAD)
       │         │
       │         ├── Module: Match Scouting
       │         ├── Module: Pit Scouting  
       │         └── Module: QR Code Scanner
       │
       └───► [ Backend Services ]
                 │
                 ├── Scout-Ops Server (Data Aggregator)
                 ├── Scout Analytics Dashboard
                 ├── Match Viewer
                 └── Scout Lookup
```

## 🎛️ Dev Control Hub (Central Orchestrator)

**The command center for the entire Scout-Ops Suite.** Dev Control is an Electron-based desktop application that serves as the central hub, allowing admins to launch, monitor, and manage all ScoutOps sub-applications from a single interface—without touching the terminal.

**Key Capabilities:**
- **App Control Panel** — Start, stop, and monitor all ScoutOps sub-apps with one click
- **Live Dev Logs** — Real-time stdout/stderr streaming from every running process
- **Merged Workspace** — Embed running web apps directly inside the control panel
- **Server Health** — Monitor connected scouting devices, sync status, and data records
- **One-Click Builds** — Android APK and iOS IPA compilation for mobile devices
- **Settings Management** — Customize ports, launch commands, and working directories for all sub-apps

## 📱 The Scout-Ops Mobile App (iOS & Android)

**One download. Zero friction.** Your scouts download the single Scout-Ops app, and they immediately have the scanner, the match tracker, and the pit scouter right in their pocket.

Instead of juggling multiple applications or dealing with App Store chaos at competition, this single download contains built-in modules for:

- **Match Scouting Module**: The primary interface for recording match performance data in real-time
- **Pit Scouting Module**: Integrated pit scouting tools for collecting team information and robot specifications
- **QR Code Scanner Module**: Built-in QR scanning to instantly ingest data without switching apps

## �️ Backend Services

- **Scout-Ops Server**: The backend aggregator that syncs everything together and handles API requests
- **Scout Analytics Dashboard**: Web-based analytics for data visualization and strategy planning
- **Match Viewer**: Web-based match footage viewer for reviewing recorded matches
- **Scout Lookup**: Team and event lookup services

---

## 🏗️ Technical Architecture

- Modular and extensible design
- App-agnostic data handling
- Supports local and networked deployments
- Scales from small teams to full competition scouting crews

---

## 🧪 Usage

1. Deploy Scout-Ops Suite on your chosen platform
2. Connect Scout-Ops scouting applications
3. Collect and store scouting data
4. Analyze, export, and strategize

---

## 🏁 Target Audience

- FIRST Robotics Competition (FRC) teams
- Scouting and strategy leads
- Developers building Scout-Ops tools
- Teams seeking a unified scouting solution

---

## 🤝 Contributing

Contributions are welcome!  
Feel free to open an issue or submit a pull request for bug fixes, features, or documentation improvements.

---

## 📜 License

This project is licensed under the license specified in the repository.

---

## 💡 Scout Smarter. Play Better. Win More.

**Scout-Ops Suite** is the foundation of a smarter, faster, and more reliable scouting system—built for FRC competition environments.
