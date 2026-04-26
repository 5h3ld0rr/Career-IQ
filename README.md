# CareerIQ

CareerIQ is a professional, high-fidelity job search and career management application built with Flutter. It leverages AI to provide candidates and recruiters with advanced tools for job matching, CV analysis, and career progression.

## 🚀 Key Features

- **AI Career Assistant**: Get personalized career advice and guidance powered by LLMs.
- **CV Analysis**: Professional CV screening and optimization suggestions.
- **Job Ecosystem**: Search, filter, and apply for jobs with real-time status tracking.
- **Recruiter Suite**: Comprehensive dashboard for managing listings, applicants, and analytics.
- **Interview Suite**: Tools for interview preparation and tracking.
- **Salary ROI**: Advanced tools for calculating salary potential and return on investment.
- **Real-time Communication**: Integrated chat and push notifications for instant updates.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart)
- **Backend**: [Firebase](https://firebase.google.com) (Auth, Firestore, Storage, Cloud Messaging)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **AI Integration**: OpenRouter API
- **Media Management**: Cloudinary & Firebase Storage
- **Authentication**: Google Sign-In & Email/Password

## 📦 Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio / VS Code
- Firebase Project

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/5h3ld0rr/Career-IQ.git
   cd Career-IQ
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Environment:**
   - Copy `.env.example` to `.env`
   - Fill in your API keys for Firebase, OpenRouter, Cloudinary, etc.

4. **Firebase Setup:**
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the respective directories.

5. **Run the application:**
   ```bash
   flutter run
   ```

## 🏗️ Architecture

The project follows a feature-first folder structure for high scalability:

- `lib/core`: Shared utilities, themes, and shell components.
- `lib/features`: Domain-specific modules (Auth, Jobs, AI, Recruiter, etc.).
- `lib/firebase_options.dart`: Auto-generated Firebase configuration.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
