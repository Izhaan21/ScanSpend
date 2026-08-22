# ScanSpend

ScanSpend is a powerful, Flutter-based mobile application designed for professionals and business owners to effortlessly track and manage their expenses. By leveraging advanced OCR (Optical Character Recognition) and Generative AI, ScanSpend allows you to quickly scan receipts and automatically extract, categorize, and log expense data with precision and "Digital Assurance."

## Features

- **Smart Receipt Scanning:** Use your device's camera or select images from your gallery to scan receipts.
- **AI-Powered Data Extraction:** Integrates with Google ML Kit for text recognition and Google Generative AI to intelligently parse and categorize expense details.
- **Location Tracking:** Automatically capture the location of your expenses using Geolocation features.
- **Secure Authentication:** Seamless and secure login using Google Sign-In and secure local storage.
- **Premium Design:** Features the "Precision Scan Design System," ensuring a highly professional, visually appealing, and intuitive user experience.

## Tech Stack

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **State Management:** Provider
- **Machine Learning & AI:** Google ML Kit Text Recognition, Google Generative AI
- **Authentication:** Google Sign-In
- **Location Services:** Geolocator, Geocoding
- **Storage:** Flutter Secure Storage, Shared Preferences

## Design System

ScanSpend follows the **Precision Scan Design System**, anchored in the concept of "Digital Assurance," balancing high-tech efficiency with institutional reliability.

- **Primary Color:** Deep Navy (`#0F172A`)
- **Secondary Color:** Vibrant Teal (`#0D9488`)
- **Typography:** Manrope (Headings & Body), Inter (Data/Mono)

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (^3.11.4)
- Android Studio or VS Code with Flutter extensions
- An Android or iOS device/emulator

## Getting Started

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd ScanSpend
   ```

2. **Install Dependencies**
   Run the following command to fetch all required packages:
   ```bash
   flutter pub get
   ```

3. **Configure API Keys**
   Ensure you configure the required API keys for Google Services and Generative AI within your environment before running the app.

4. **Run the Application**
   ```bash
   flutter run
   ```

## Project Structure

- `lib/screens/` - Contains the UI for all application screens (e.g., Authentication, Home, Settings).
- `lib/services/` - Business logic and external service integrations (Auth, API calls).
- `lib/providers/` - State management classes using the Provider package.
- `lib/models/` - Data models representing core entities (like `ItemModel`).
- `DESIGN.md` - Documentation of the application's Design System.
