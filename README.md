# SocialFriction

Flutter app with Firebase Authentication, Firestore, and Firebase Storage.

## Firebase Configuration

This project is already wired to Firebase project:

- Project ID: socialfriction-37037
- Android App ID: 1:461233756510:android:bdba79b18daed9482bd7cf
- iOS App ID: 1:461233756510:ios:93866d44c2e076b42bd7cf

### 1. Install prerequisites

1. Install Flutter and run:

	flutter doctor

2. Install Firebase CLI:

	npm install -g firebase-tools

3. Install FlutterFire CLI:

	dart pub global activate flutterfire_cli

### 2. Login and configure Firebase files

1. Login:

	firebase login

2. From project root, regenerate platform config if needed:

	flutterfire configure --project=socialfriction-37037

This updates:

- lib/firebase_options.dart
- android/app/google-services.json

For iOS, also download GoogleService-Info.plist from Firebase Console and place it in:

- ios/Runner/GoogleService-Info.plist

### 3. Enable Authentication providers

In Firebase Console:

1. Open Authentication -> Sign-in method.
2. Enable Email/Password.
3. Enable Google sign-in.
4. Add support email and save.

### 4. Configure Firestore and Storage rules

Rules files in this repo:

- firestore.rules
- storage.rules

Deploy rules:

firebase deploy --only firestore:rules,storage

### 5. iOS Google sign-in checklist

Ensure iOS app in Firebase uses bundle id:

- com.example.socialFriction

Info.plist is configured with:

- Google URL scheme (reversed iOS client id)
- Photo library and camera usage descriptions

### 6. Run the app

1. Get packages:

	flutter pub get

2. Run:

	flutter run

## Notes

- Authentication and profile uploads use Firebase Auth + Firebase Storage.
- User profile and app settings sync through Firestore collection users/{uid}.
