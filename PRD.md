# 📄 PRODUCT REQUIREMENT DOCUMENT (PRD)

## 🧾 ScanSpend – Smart Expense Scanner (1-Week MVP)

---

## 🧭 1. Product Overview

**Product Name:** ScanSpend
**Platform:** Android (Flutter)
**Type:** AI-powered expense tracking app

**Description:**
ScanSpend enables users to scan receipts, extract expense data using OCR + AI, review/edit it, and store it for tracking.

---

## 🎯 2. Objective (1 Week)

Build a working MVP demonstrating:

👉 Scan → Extract → Review → Save → View History

Focus on:

* Core functionality
* Clean UI
* End-to-end flow

---

## 💡 3. Problem Statement

Manual expense tracking is:

* Slow
* Error-prone
* Inconvenient

---

## ✅ 4. Solution

* Scan receipt
* Extract data automatically
* Allow correction
* Save and view later

---

## 🔁 5. Core User Flow

1. User opens app → Dashboard
2. Clicks “Scan Receipt”
3. Captures image
4. OCR extracts text
5. AI parses data
6. User reviews & edits
7. Saves expense
8. View in History

---

## 📱 6. Screens (MVP)

---

### 🏠 6.1 Dashboard Screen

**Purpose:** Overview + entry point

**UI Elements:**

* AppBar (ScanSpend)
* Total monthly spend (card)
* Quick stats (optional)
* “Scan Receipt” button (primary CTA)

---

### 📸 6.2 Scan Receipt Screen

**Purpose:** Capture receipt

**UI Elements:**

* Camera preview (or placeholder)
* Scan overlay frame
* Buttons:

  * Capture
  * Upload from gallery

---

### 🧠 6.3 Review Scan Screen (CORE)

**Purpose:** Verify AI output

**UI Elements:**

* Editable list:

  * Item name (TextField)
  * Price (TextField)
* Total amount
* Save button

**Behavior:**

* User can edit all values

---

### 📂 6.4 History Screen

**Purpose:** Show saved expenses

**UI Elements:**

* ListView of expenses
* Each item:

  * Date
  * Total amount

---

### 👤 6.5 Profile Screen

**Purpose:** User info & settings

**UI Elements:**

* User name (static for MVP)
* App info
* Logout (optional)

---

## 🧠 7. Functional Requirements

---

### 7.1 OCR

* Extract text from image using ML Kit

---

### 7.2 AI Parsing

Convert text → JSON:

```json id="p4r6jk"
{
  "items": [
    { "name": "Item", "price": 100 }
  ],
  "total": 100
}
```

---

### 7.3 Editing

* User can modify extracted data

---

### 7.4 Save Data

* Store in Firebase Firestore

---

### 7.5 Fetch Data

* Display saved expenses in History

---

## 🧱 8. Flutter Architecture

---

### 🔷 Architecture Pattern

**Layered + Modular Architecture**

---

### 📁 Folder Structure

```plaintext id="f89gqp"
lib/
 ├── main.dart
 ├── core/
 │    ├── theme/
 │    ├── constants/
 │
 ├── models/
 │    └── expense_model.dart
 │
 ├── services/
 │    ├── ocr_service.dart
 │    ├── ai_service.dart
 │    ├── firestore_service.dart
 │
 ├── providers/
 │    └── expense_provider.dart
 │
 ├── screens/
 │    ├── dashboard_screen.dart
 │    ├── scan_screen.dart
 │    ├── review_screen.dart
 │    ├── history_screen.dart
 │    ├── profile_screen.dart
 │
 ├── widgets/
 │    ├── expense_card.dart
 │    ├── item_tile.dart
```

---

### 🔄 Data Flow

```plaintext id="q6nx3v"
Image
 ↓
OCR Service
 ↓
Raw Text
 ↓
AI Service
 ↓
Structured Data
 ↓
Provider (State)
 ↓
UI (Review Screen)
 ↓
Firestore
 ↓
History Screen
```

---

### 🧠 State Management

* Provider
* Central ExpenseProvider

Handles:

* Current scan data
* List of expenses
* Save operation

---

## ☁️ 9. Tech Stack

* Flutter (UI)
* Firebase Firestore
* Google ML Kit (OCR)
* Gemini API / OpenAI
* Provider

---

## ⚡ 10. Performance Goals

* OCR < 2 sec
* AI < 5 sec
* Smooth UI

---

## 🎨 11. UI Guidelines

* Clean fintech UI
* Consistent padding (16px)
* Rounded cards (12px)

---

## 🧪 12. Testing

* Test with simple receipts
* Ensure:

  * OCR works
  * AI returns valid JSON
  * Save works

---

## 📅 13. 1-Week Plan

### Day 1–2

* Setup project
* Dashboard + Scan UI

---

### Day 3–4

* OCR + AI integration
* Review screen

---

### Day 5

* Firestore save/fetch
* History screen

---

### Day 6

* Profile screen
* UI polish

---

### Day 7

* Testing
* Demo

---

## ⚠️ 14. Risks

| Risk            | Fix         |
| --------------- | ----------- |
| OCR errors      | Manual edit |
| AI wrong output | Validation  |
| Slow API        | Loader      |

---

## ✅ 15. Definition of Done

* Scan works
* OCR extracts text
* AI parses data
* User edits
* Data saves
* History shows data

---

## 🚀 16. Future Scope

* Analytics dashboard
* Categories
* Search
* Offline mode

---

## 🏁 17. Conclusion

ScanSpend MVP demonstrates:

* AI integration
* Mobile development
* Real-world use case

Strong portfolio project.

---

END OF DOCUMENT
