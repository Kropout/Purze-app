# Purze 💰
### Automatic UPI Finance Tracker

Purze reads your UPI SMS transactions, organizes them by category, and gives you a clean analytics dashboard — all stored locally on your device. No accounts, no cloud, no data sharing.

---

## Features

- **Automatic SMS Parsing** — reads incoming UPI messages from all major Indian banks and extracts transaction details instantly
- **Budget Tracking** — set a monthly budget and track spending in real time with a visual progress ring
- **Category Breakdown** — transactions auto-categorized into Food, Travel, Shopping, Bills, and more
- **Analytics Dashboard** — spending trends and insights at a glance
- **Dark & Light Mode** — full theme support
- **100% Local** — all data stored on-device using Hive. Nothing leaves your phone.

---

## Screenshots

> Coming soon

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Local Database | Hive |
| Platform | Android, Web |

---

## Getting Started

### Prerequisites
- Flutter SDK (3.x or above)
- Android Studio / VS Code
- Android device or emulator

### Run Locally

```bash
git clone https://github.com/Kropout/purze-app.git
cd purze-app
flutter pub get
flutter run
```

### Build APK

```bash
flutter build apk
```

---

## Roadmap

- [x] UPI SMS parser
- [x] Budget tracking with progress ring
- [x] Category-based analytics
- [x] Dark / Light mode
- [x] Onboarding flow
- [ ] Manual transaction entry
- [ ] Per-category budgets
- [ ] Export transactions as CSV
- [ ] Google Play release

---

## Privacy

Purze requests SMS read permission solely to detect UPI transactions. No data is transmitted to any server. All transaction data is stored locally on your device and can be deleted at any time from Settings.

---

## Author

**Piyush Gupta**  
ECE @ SRM Institute of Science and Technology  
[GitHub](https://github.com/Kropout)

---

> *Purze — because knowing where your money went shouldn't require a bank login.*