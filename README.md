# E-Learning App

A comprehensive mobile application for accessing educational courses and tests, built with Flutter and Firebase.

## Features

- **User Authentication**: Login, registration, and profile management
- **Course Management**: Browse courses, view details, and enroll
- **Testing System**: Take tests with automatic grading
- **Local Data Storage**: Save progress using Hive
- **UI Animations**: Enhanced user experience with animations
- **Multilingual Support**: English and Ukrainian languages
- **Theme Customization**: Light, dark, and system themes

## Technology Stack

- **Frontend**: Flutter/Dart
- **Backend**: Firebase (Authentication, Firestore, Storage)
- **State Management**: Riverpod
- **Local Storage**: Hive
- **Navigation**: Go Router
- **Localization**: Flutter Intl
- **UI Enhancement**: Flutter Animate, Lottie

## Project Structure

```
lib/
├── core/
│   ├── models/         # Data models
│   ├── services/       # API and storage services
│   ├── theme/          # App theme configuration
│   ├── utils/          # Utility functions and providers
│   └── widgets/        # Reusable widgets
├── features/
│   ├── auth/           # Authentication feature
│   ├── courses/        # Courses feature
│   ├── tests/          # Tests feature
│   └── profile/        # User profile feature
├── l10n/              # Localization files
└── main.dart          # App entry point
```

## Installation

### Prerequisites

- Flutter SDK (3.7.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code
- Firebase account

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/e_learning_app.git
   cd e_learning_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   - Create a new Firebase project
   - Add Android and iOS apps to your Firebase project
   - Download and add the configuration files (google-services.json for Android, GoogleService-Info.plist for iOS)
   - Enable Authentication, Firestore, and Storage in Firebase console

4. Run the app:
   ```bash
   flutter run
   ```

## Testing

The project includes examples of different types of tests:

```bash
# Run unit tests
flutter test

# Run widget tests
flutter test --tags=widget

# Run integration tests
flutter test integration_test
```

## Localization

The app supports multiple languages. To add a new language:

1. Create a new ARB file in the `lib/l10n` directory
2. Add the new locale to the `supportedLocales` list in `main.dart`
3. Run the app to generate the localization files

## State Management

The app uses Riverpod for state management. Each feature has its own controllers that manage the state and business logic.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
