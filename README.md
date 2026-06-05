# Purze 💰
### Automatic UPI Finance Tracker

Purze reads your UPI SMS transactions, organizes them by category, and gives you a clean analytics dashboard — all stored locally on your device. No accounts, no cloud, no data sharing.

---

## Features

**Core Finance Tracking**
- **Automatic SMS Parsing** — parses UPI transactions from 30+ Indian banks (ICICI, HDFC, SBI, PNB, Axis, Kotak, etc.) with intelligent merchant extraction and error recovery
- **Real Transaction Import** — on Android, Purze reads your SMS inbox and imports all UPI transactions automatically. On web, mock test data for validation
- **Estimated Balance** — calculates available balance from starting amount + credits - debits, based on real UPI transactions
- **Budget Tracking** — set monthly budget, track spending in real time with visual progress ring, get alerts when overbudget
- **Smart Category Detection** — automatically categorizes transactions into Food, Travel, Shopping, Bills, Entertainment, Health, Other

**Analytics & Insights**
- **Analytics Dashboard** — monthly trends (line chart), weekly spending (bar chart), top merchants, spending breakdown by category
- **Smart Insights** — budget status alerts, biggest expenses, essential vs non-essential spending analysis, actionable recommendations
- **Month Navigation** — browse spending history across months with dynamic chart updates

**Security & Privacy**
- **PIN Lock** — 4-digit keypad-style PIN protection with biometric authentication as primary unlock method
- **Auto-Lock Timeout** — customizable lock settings (Immediate, 1 min, 5 mins, 10-30 mins, 1 hour) based on inactivity
- **Biometric Authentication** — fingerprint/face unlock with graceful PIN fallback for devices without biometrics or unenrolled users
- **100% Local Storage** — all data stored on-device using Hive. Zero transmission to any server. Your data never leaves your phone
- **Manual Data Control** — clear all data and reset app anytime from Settings

**User Experience**
- **Onboarding Flow** — 5-step setup (welcome, name, budget, starting balance, SMS permission) guides new users through initial configuration
- **Dark & Light Mode** — full theme support with toggle, persistent theme preference
- **Settings Screen** — manage name, budget, starting balance, security (PIN/biometric), view app version, access privacy policy and T&C
- **Input Validation** — name (max 20 chars, letters only), budget (max ₹10L), starting balance, phone number (10 digits)
- **Empty States** — graceful handling when no transactions exist, prompts user to enable SMS permission or wait for transactions
- **Responsive Design** — optimized for mobile (Android APK) and web (Chrome localhost for testing)

---

## Screenshots

> Coming soon

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Local Database | Hive (encrypted local storage) |
| Platforms | Android (APK), Web (Chrome) |
| Testing | Unit tests for 50+ SMS parsing scenarios |

---

## Getting Started

### Prerequisites
- Flutter SDK (3.x or above)
- Android Studio / VS Code
- Android device or emulator (for native APK)
- Chrome browser (for web testing)

### Run Locally (Web)

```bash
git clone https://github.com/Kropout/purze-app.git
cd purze_app
flutter pub get
flutter run -d web-server
# Opens at http://localhost:PORT (see terminal for exact port)
# Web version loads mock SMS test data automatically
```

### Run on Android Device

```bash
flutter run
# Device must have USB debugging enabled
# Grants SMS read permission on first launch
```

### Build APK (Release)

```bash
flutter build apk
# APK at: build/app/outputs/flutter-apk/app-release.apk
# Transfer to phone via WhatsApp, email, or USB
```

---

## Architecture

**Data Flow:**
1. SMS Importer reads inbox (Android) or mock data (Web)
2. SMS Parser extracts: amount, merchant, debit/credit, date
3. Category Engine auto-assigns transaction category
4. Hive Database stores TransactionModel locally
5. Riverpod providers expose data to UI
6. Screens display transactions, analytics, budgets

**Parser Strategy:**
- Generic semantic extraction (works for any bank format)
- Bank-specific fallback patterns (ICICI, SBI, HDFC, PNB)
- Rejects spam: OTPs, promotional, failed transactions
- Handles edge cases: reference number rejection, long name preservation, merchant code prefixes

---

## Roadmap

- [x] UPI SMS parser (30+ banks)
- [x] Budget tracking with progress ring
- [x] Category-based analytics with smart insights
- [x] Dark / Light mode
- [x] Onboarding flow (5 steps)
- [x] PIN lock + biometric security
- [x] Settings screen (name, budget, balance, security)
- [x] Privacy Policy & Terms & Conditions
- [x] Input validation & error handling
- [x] Web support with mock data
- [ ] Manual transaction entry
- [ ] Per-category budgets
- [ ] Export transactions as CSV
- [ ] Recurring transaction detection
- [ ] Google Play Store release
- [ ] Spending forecasts & predictions

---

## Known Limitations (v1.0.0)

- **Parser Accuracy:** ~70-80% on first parse. Accuracy improves as edge cases are discovered and fixed
- **Biometric:** Requires device enrollment; shows graceful fallback to PIN if unavailable
- **Analytics:** Most meaningful with 2+ weeks of transaction history
- **Web Mock Data:** Limited to 50 test transactions. Real SMS only available on Android

---

## Privacy & Security

**Data Handling:**
- Purze requests SMS read permission solely to detect UPI transaction messages
- All SMS data is processed locally; no data is transmitted to any external server
- Transaction data stored encrypted in Hive database on your device
- You maintain complete control: delete all data anytime from Settings

**Permissions Requested:**
- **SMS_READ** (Android) — to import UPI transaction messages from your SMS inbox
- **USE_BIOMETRIC** (Android) — for fingerprint/face unlock authentication
- **Permission not required on web** — web version uses test data only

---

## Version History

**v1.0.0 (Current)**
- Initial public release
- SMS parser for 30+ Indian banks
- Budget tracking & analytics
- PIN + biometric security
- Dark/light mode
- Onboarding flow
- Privacy-first design

---

## Contributing

Contributions welcome! Areas where help is needed:
- SMS parser improvements (more bank formats, edge cases)
- Analytics enhancements (forecasting, trends)
- UI/UX polish (design, animations)
- Test coverage expansion

---

## License

MIT License — see LICENSE file for details

---

## Author

**Piyush Gupta**  
B.Tech Electronics & Communication Engineering  
SRM Institute of Science and Technology, Kattankulathur  
[GitHub: @Kropout](https://github.com/Kropout)  
Email: piyushgupta12042006@gmail.com

---

## Support

Found a bug or have a suggestion? Open an issue on [GitHub Issues](https://github.com/Kropout/purze-app/issues)

---

> *Purze — because knowing where your money went shouldn't require a bank login.*