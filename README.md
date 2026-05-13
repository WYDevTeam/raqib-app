# راقب — Raqib

**"Know your numbers. Own your future."**

**Raqib (راقب)** is an Arabic-first personal finance app that gives you a real-time picture of your financial health. Track every transaction, monitor your investments, manage debts and trust funds, and build a custom financial dashboard — all stored locally on your device.

> 🏆 Built during **[Salam Hack 2026](https://salamhack.com/index.html#in-hackathon)** — a fintech hackathon focused on financial literacy and management tools for Arabic speakers

<!-- Add a banner/hero screenshot here (recommended: 1000x480px) -->
<!-- <img width="1000" height="480" alt="Raqib Home" src="..."> -->

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)

## Team Members
- **Wafaa** — [@WafaaSisalem](https://github.com/WafaaSisalem)
- **Yasmeen Abu Shaar**

## Table of Contents
1. [Features](#features)
2. [Tech Stack](#tech-stack)
3. [Installation](#installation)
4. [Screenshots](#screenshots)
5. [Future Enhancements](#future-enhancements)
6. [Contact](#contact)

---

## Features

### 📊 Smart Dashboard
- Real net worth card with **Conservative / Total** toggle
  - Conservative: excludes debts others owe you
  - Total: includes all receivables
- Customizable overview grid — show only the cards that matter to you
- **Custom Formula Builder**: create your own financial metrics using built-in variables (liquid cash, gold, crypto, P&L, spending rate, and more)

### 💸 Transactions
- Log income and expenses with categories
- Filter and search your transaction history
- **Recurring Rules**: set up automatic recurring transactions (daily, weekly, monthly) — processed on launch

### 📈 Investments
- Track assets across classes: gold, silver, crypto, platinum, palladium, and more
- Log buy/sell transactions per asset
- Realized and unrealized P&L calculated automatically
- **Live price feeds**: metals prices via [metals.dev](https://metals.dev), crypto prices via Binance

### 🎯 Budget
- Set spending budgets per category
- Visual progress tracking against your budget

### 🤝 Debts & Amanah (الديون والأمانات)
- **Debts you gave (ملكك)**: money others owe you — track payments and settle
- **Amanah held (أمانات عندي)**: trust funds you're holding for others — not yours, excluded from your net worth

### 🤖 AI-Powered Excel / CSV Import
- Upload your bank export (`.xlsx` or `.csv`) and the app analyzes it automatically
- Powered by **Groq API (Llama 3.1)** — understands your file structure, detects columns, and classifies rows into transactions, investments, debts, and amanah
- Asks clarifying questions only for genuinely ambiguous entries (e.g. money sent to a person — debt or expense?)
- Batch-processes large files with progress tracking

### ⚙️ Settings & Calculation Modes
- Categories management (add, edit, delete)
- Customize core formulas: net worth, liquid cash, real P&L
- Cumulative mode: last 12 months or all time
- Fine-grained control over how amanah and debts affect your net worth

---

## Tech Stack

**Frontend:** Flutter (Dart), BLoC / Cubit, GoRouter

**Storage:** Hive (local, offline-first)

**AI:** Groq API — Llama 3.1 8B Instant

**Live Prices:** metals.dev (gold, silver, platinum, palladium) · Binance (crypto)

**Architecture:** Clean Architecture — `data` / `domain` / `presentation` per feature

**Other:** get_it (DI), fl_chart, Cairo font

---

## Installation

### Prerequisites
- Flutter SDK
- Groq API key — [get one free at console.groq.com](https://console.groq.com)
- metals.dev API key — [get one at metals.dev](https://metals.dev)

### Steps

1. Clone the repository
   ```bash
   git clone <repository-url>
   cd raqib
   flutter pub get
   ```

2. Create a `.env` file in the project root:
   ```env
   GROQ_API_KEY=your_groq_api_key
   METALS_DEV_API_KEY=your_metals_dev_api_key
   ```

3. Run the app
   ```bash
   flutter run
   ```

> All financial data is stored locally on device via Hive. No user data leaves the device.

---

## Screenshots

<!-- Add screenshots here once available -->
<!-- Recommended: dashboard, transactions, investments, debts & amanah, import screens -->

---

## Future Enhancements

- [ ] Data export (CSV / Excel)
- [ ] Backup & restore
- [ ] Charts and spending trends over time
- [ ] Notifications for recurring transactions
- [ ] Multi-currency support with exchange rates
- [ ] Savings goals tracker
- [ ] AI-powered monthly spending summaries

---

## Contact

- **Email**: [wafaaiyadsisalem@gmail.com](mailto:wafaaiyadsisalem@gmail.com)
- **GitHub**: [WafaaSisalem](https://github.com/WafaaSisalem)
