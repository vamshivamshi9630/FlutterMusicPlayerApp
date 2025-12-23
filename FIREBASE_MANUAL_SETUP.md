# Manual Firebase Setup Guide

Since npm/Firebase CLI isn't available, you can manually get your Firebase credentials and add them to the code.

## Step 1: Get Your Firebase Credentials

1. **Open Firebase Console:**
   - Go to: https://console.firebase.google.com/project/musicplayerapp-flutter/settings/general

2. **Add a Flutter App (if not already added):**
   - Click "Add app" button
   - Select "Flutter"
   - Download the `google-services.json` (for Android) or `GoogleService-Info.plist` (for iOS)
   - Or if already added, go to your app settings

3. **Find Your Web Configuration:**
   - Go to Project Settings → Your apps
   - Click on your Flutter app
   - Scroll down to "SDK setup and configuration"
   - Copy the JSON configuration

4. **Or Access via REST API:**
   - Go to Project Settings → General tab
   - Look for:
     - **API Key**
     - **Project ID** (musicplayerapp-flutter)
     - **Messaging Sender ID**
     - **App ID**
     - **Database URL**
     - **Storage Bucket**

## Step 2: Update firebase_options.dart

Replace the template values in `lib/firebase_options.dart`:

```dart
static const FirebaseOptions windows = FirebaseOptions(
  apiKey: 'YOUR_API_KEY_HERE',
  appId: 'YOUR_APP_ID_HERE',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID_HERE',
  projectId: 'musicplayerapp-flutter',
  authDomain: 'musicplayerapp-flutter.firebaseapp.com',
  storageBucket: 'musicplayerapp-flutter.firebasestorage.app',
);
```

## Step 3: Enable Google Sign-In in Firebase Console

1. Go to: **Authentication** → **Sign-in method**
2. Click "Google"
3. Toggle it ON
4. Click Save

## Step 4: Set Firestore Security Rules

1. Go to: **Firestore Database** → **Rules**
2. Replace with:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

3. Click Publish

## Step 5: Run the App

```powershell
flutter clean
flutter pub get
flutter run
```

## Current Status

- ✅ Cloud sync code is ready in:
  - `lib/services/auth_service.dart`
  - `lib/services/cloud_sync_service.dart`
  - `lib/services/favorites_manager.dart`
  - `lib/screens/login_screen.dart`

- ⏳ Waiting for: Firebase credentials in `lib/firebase_options.dart`

- Firebase initialization is temporarily skipped in `lib/main.dart` (will be enabled once credentials are added)

## Where to Find Your Credentials

The easiest way to find all your Firebase config values:

### For Windows/Web:
1. Firebase Console → Project Settings (⚙️)
2. Click on "Add app" or select existing app
3. Select "Web" platform
4. You'll see a code snippet with all the values:
   ```javascript
   // Example from Firebase
   const firebaseConfig = {
     apiKey: "AIza...",
     authDomain: "musicplayerapp-flutter.firebaseapp.com",
     projectId: "musicplayerapp-flutter",
     storageBucket: "musicplayerapp-flutter.firebasestorage.app",
     messagingSenderId: "123456789",
     appId: "1:123456789:web:abcd1234...",
   };
   ```

### Map these to firebase_options.dart:
- `apiKey` → `apiKey`
- `authDomain` → `authDomain`
- `projectId` → `projectId`
- `storageBucket` → `storageBucket`
- `messagingSenderId` → `messagingSenderId`
- `appId` → `appId`

## Questions?

Once you add the credentials to `firebase_options.dart` and uncomment the Firebase initialization in `main.dart`, the cloud sync will be fully functional!
