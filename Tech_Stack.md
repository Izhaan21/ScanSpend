# ⚙️ ScanSpend – Tech Stack

## 📱 Frontend

* **Framework:** Flutter (latest stable)
* **Language:** Dart
* **UI:** Material Design (custom themed)
* **State Management:** Provider

---

## 🧠 AI & Processing

### 🔍 OCR (Text Extraction)

* **Library:** Google ML Kit (`google_mlkit_text_recognition`)
* **Purpose:** Extract raw text from receipt images

---

### 🤖 AI Parsing

* **API:** Gemini Pro API *(preferred)*
* **Alternative:** OpenAI API
* **Purpose:** Convert OCR text into structured JSON (items, prices, total)

---

## ☁️ Backend & Database

### 🔥 Firebase

* **Firestore:** Store expense data
* **Authentication (optional):** User login
* **Storage (optional):** Store receipt images

---

## 🌐 Networking

* **HTTP Client:** `http` package
* **Purpose:** API calls to AI services

---

## 📦 Key Flutter Packages

```yaml
dependencies:
  flutter:
    sdk: flutter

  image_picker: ^1.0.0
  google_mlkit_text_recognition: ^0.11.0
  provider: ^6.0.5
  cloud_firestore: ^4.0.0
  firebase_core: ^2.0.0
  http: ^1.1.0
```

---

## 🏗️ Architecture

* **Pattern:** Layered Architecture
* **Structure:**

  * UI (Screens & Widgets)
  * Business Logic (Provider)
  * Services (OCR, AI, Firestore)
  * Models (Data structures)

---

## 🔄 Data Flow

```
Image Capture
   ↓
OCR (ML Kit)
   ↓
Raw Text
   ↓
AI Parsing (Gemini/OpenAI)
   ↓
Structured Data (JSON)
   ↓
UI (Review Screen)
   ↓
Firestore (Save)
   ↓
History Screen
```

---

## 🎨 UI/UX

* Clean fintech-style UI
* Consistent spacing (16px)
* Rounded cards (12px)
* Dark/Light theme (optional)

---

## ⚡ Performance Goals

* OCR processing < 2 seconds
* AI response < 5 seconds
* Smooth UI with async handling

---

## 🔐 Security

* API keys stored securely (not in UI code)
* Firebase rules for user data protection

---

## 🚀 Deployment

* **Build Type:** Android (AAB)
* **Platform:** Google Play Store

---

## 🔮 Future Enhancements

* Expense categorization
* Analytics & reports
* Offline support
* Search & filters
* Multi-currency support

---

END OF FILE
