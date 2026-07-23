# CampusScore Frontend

This is the mobile frontend for CampusScore, built using [Flutter](https://flutter.dev/). It provides the user interface for individuals to upload their financial data (like bank statements) and view their alternative credit scores in a beautiful, modern app.

## 📱 Features

- **Cross-Platform**: Built with Flutter for smooth performance on both iOS and Android.
- **Firebase Authentication**: Secure user login and registration powered by Firebase.
- **Realtime Database**: User data and score history synced using Firebase Realtime Database.
- **Bank Statement Uploads**: Users can select and upload PDF bank statements using the `file_picker` package, which are sent to the FastAPI backend for analysis.
- **Location & Mapping**: Integrates `google_maps_flutter` and `geolocator` for map-based or location-aware features.
- **Custom Typography**: Uses modern fonts like `Outfit`, `Plus Jakarta Sans`, and custom assets to provide a premium UI feel.

## 🛠️ Tech Stack & Key Packages

- **State Management**: `provider`
- **Networking**: `http` (for communicating with the backend FastAPI server)
- **Services**: 
  - `firebase_core`, `firebase_auth`, `firebase_database`
  - `google_sign_in`
- **Utilities**: `file_picker`, `sqflite`, `path_provider`, `intl`

## ⚙️ Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.9.2`)
- Android Studio or Xcode (depending on your target platform)
- Ensure you have a connected device or an active emulator.

### Setup Instructions

1. **Get Dependencies**:
   Navigate to the `Frontend` directory and fetch the Flutter packages:
   ```bash
   flutter pub get
   ```

2. **Firebase Configuration**:
   This project relies on Firebase. To run it locally or build it, you will need to:
   - For **Android**: Place your `google-services.json` file in the `android/app` directory.
   - For **iOS**: Place your `GoogleService-Info.plist` file in the `ios/Runner` directory.
   *(Note: These files are typically ignored in version control for security).*

3. **Run the App**:
   Start the application on your connected device/emulator:
   ```bash
   flutter run
   ```

## 🔗 Connecting to the Backend

The frontend communicates with the CampusScore FastAPI backend. Ensure your backend server is running locally (usually on `http://127.0.0.1:8000`) or update the API base URL in the Flutter code to point to your deployed backend instance before testing the `/score` or `/upload_statement` features.
