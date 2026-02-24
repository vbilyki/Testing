# WealthWise - iOS Expense Tracker & Financial Coach

A modern iOS personal finance app built with SwiftUI that helps you **save first, spend smarter**.

## Core Financial Philosophy

### Pay Yourself First
When income arrives, savings are set aside **immediately** before any spending occurs. You set a savings rate (default 20%) and that amount is automatically earmarked. This is the #1 rule proven to build wealth.

### 50/30/20 Rule
Budget suggestions follow the proven allocation:
- **50%** → Needs (groceries, transport, utilities, health)
- **30%** → Wants (dining, entertainment, shopping)
- **20%** → Savings (already set aside via Pay Yourself First)

### Zero-Based Budgeting
Every hryvnia has a job. All income is allocated across savings + spending categories, leaving nothing unplanned.

---

## Features

### Dashboard
- Monthly financial health score (0–100)
- Pay Yourself First summary — savings vs spendable amounts
- Income / expenses / net cash flow overview
- Budget category spending with visual progress bars
- Recent transactions
- Top savings goal progress

### Budget Planning
- Create monthly budgets with custom income
- Set savings rate with interactive slider (5%–50%)
- Auto-suggest allocations using 50/30/20 rule
- Per-category spending tracking
- Over-budget warnings

### Monobank Integration
- Connect via Monobank API token (from the app's API settings)
- Auto-sync transactions for the current month
- Automatic MCC-based categorization (groceries, transport, dining, health, etc.)
- Rate-limit aware (Monobank allows 1 statement request/min)
- Maps 60+ MCC codes to spending categories

### Savings Goals
- Create goals with emoji, target amount, deadline, priority
- Monthly contribution tracking
- ETA calculation based on contribution rate
- Track multiple goals simultaneously
- Completion celebrations

### AI Financial Insights (Claude AI)
- Overall financial health analysis
- Top 3 personalized insights (warnings, successes, tips) with impact levels
- Actionable 3-step improvement plan
- Spending pattern detection
- Unusual transaction alerts
- Optimized savings rate recommendation
- Category-level expense reduction suggestions
- Pay Yourself First personalized advice

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI |
| Data | SwiftData (iOS 17+) |
| Async | Swift Concurrency (async/await) |
| Banking | Monobank Open API |
| AI | Claude claude-opus-4-5 (Anthropic API) |
| State | ObservableObject + @Query |
| Min iOS | iOS 17.0 |

---

## Project Structure

```
WealthWise/
├── App/
│   ├── WealthWiseApp.swift          # Entry point, SwiftData container
│   └── ContentView.swift            # Tab navigation
├── Models/
│   ├── TransactionModel.swift       # SwiftData transaction model
│   ├── BudgetModel.swift            # Monthly budget + category items
│   ├── SavingsGoalModel.swift       # Savings goal tracking
│   ├── MonobankAccountModel.swift   # Linked bank account + API models
│   └── CategoryModel.swift         # MCC code → category mapping
├── Services/
│   ├── MonobankService.swift        # Monobank API client
│   ├── AIService.swift              # Claude AI integration
│   └── BudgetService.swift         # Pay Yourself First logic, scoring
├── ViewModels/
│   ├── DashboardViewModel.swift
│   ├── BudgetViewModel.swift
│   ├── TransactionViewModel.swift
│   ├── SavingsViewModel.swift
│   └── AIInsightsViewModel.swift
├── Views/
│   ├── Components/CardView.swift    # Reusable UI components
│   ├── Dashboard/DashboardView.swift
│   ├── Budget/BudgetView.swift
│   ├── Transactions/TransactionsView.swift
│   ├── Savings/SavingsView.swift
│   ├── Insights/AIInsightsView.swift
│   └── Settings/
│       ├── SettingsView.swift       # Monobank + AI key setup
│       └── OnboardingView.swift
└── Resources/
    └── AppTheme.swift               # Colors, gradients, extensions
```

---

## Setup Instructions

### 1. Open in Xcode
```bash
open WealthWise/WealthWise.xcodeproj
```
Requires Xcode 15+ and iOS 17 SDK.

### 2. Connect Monobank (Optional)
1. Open Monobank app → Settings → Other → API
2. Request an API token
3. In WealthWise → Settings → Connect Monobank → paste token
4. Tap sync button on Dashboard to import transactions

### 3. Enable AI Insights (Optional)
1. Get an API key from [console.anthropic.com](https://console.anthropic.com)
2. In WealthWise → Settings → Add Anthropic API Key
3. Go to AI Insights tab → Analyze My Finances

### 4. Create Your First Budget
1. Go to Budget tab
2. Enter your monthly income
3. Set savings rate (recommended: 20%)
4. Allocate remaining budget across categories, or use Auto-Suggest

---

## Monobank API Details

- **Base URL:** `https://api.monobank.ua`
- **Auth:** `X-Token` header
- **Rate limit:** 1 statement request per 60 seconds
- **Endpoints used:**
  - `GET /personal/client-info` — account info
  - `GET /personal/statement/{account}/{from}/{to}` — transaction history

## Security Notes

- API tokens are stored in `UserDefaults` (for MVP; use Keychain in production)
- No financial data leaves the device except for AI analysis requests
- AI analysis sends anonymized budget summaries (no account numbers or personal IDs)

---

## MCC Category Mapping

The app maps 60+ Merchant Category Codes to budget categories:

| Category | MCC Codes |
|---|---|
| Groceries | 5411, 5412, 5441, 5451, 5462, 5499 |
| Dining | 5812, 5813, 5814 |
| Transport | 4111, 4112, 4121, 4131 |
| Fuel | 5541, 5542 |
| Health | 5047, 5122, 5912, 8011–8099 |
| Entertainment | 5735, 7832, 7922, 7941, 7993, 7999 |
| Utilities | 4900, 4911, 4924, 4941, 4961 |
| Education | 5942, 8211–8299 |
| Shopping | 5311, 5600–5699, 5732, 5734 |
| Travel | 4411, 4511, 7011 |

Unrecognized MCC codes fall back to keyword matching on transaction descriptions.
