# Firebase Configuration Guide

This guide explains how to set up Firebase for the InContext app securely.

## Overview

All Firebase secrets are stored in the `.env` file (which is gitignored) to prevent exposing sensitive credentials in version control.

## Setup Instructions

### 1. Create your `.env` file

Copy the example file and fill in your Firebase credentials:

```bash
cp .env.example .env
```

### 2. Get Firebase Configuration Values

#### For iOS:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Project Settings** (gear icon) > **General**
4. Scroll to **Your apps** section
5. Select your iOS app (or add one if you haven't)
6. Download the `GoogleService-Info.plist` file
7. Copy the values from the plist file to your `.env` file:
   - `IOS_API_KEY` → API_KEY
   - `IOS_APP_ID` → GOOGLE_APP_ID
   - `IOS_MESSAGING_SENDER_ID` → GCM_SENDER_ID
   - `IOS_PROJECT_ID` → PROJECT_ID
   - `IOS_STORAGE_BUCKET` → STORAGE_BUCKET
   - `IOS_CLIENT_ID` → CLIENT_ID
   - `IOS_BUNDLE_ID` → BUNDLE_ID

#### For Android:
1. In Firebase Console, select your Android app
2. Download the `google-services.json` file
3. Copy the values from the JSON file to your `.env` file:
   - `ANDROID_API_KEY` → current_key from api_key
   - `ANDROID_APP_ID` → mobilesdk_app_id
   - `ANDROID_MESSAGING_SENDER_ID` → project_number
   - `ANDROID_PROJECT_ID` → project_id
   - `ANDROID_STORAGE_BUCKET` → storage_bucket

#### For Web:
1. In Firebase Console, select your Web app
2. Copy the config values to your `.env` file

### 3. Configure Google Sign-In for iOS

The Google Sign-In URL scheme has already been added to `ios/Runner/Info.plist`. Make sure your `IOS_CLIENT_ID` in `.env` matches the CLIENT_ID from your Firebase project.

The URL scheme is automatically configured based on your REVERSED_CLIENT_ID from Firebase.

## Security Notes

### Files that are gitignored:
- `.env` - Contains all your secrets
- `GoogleService-Info.plist` - iOS Firebase config (secrets are in .env instead)
- `google-services.json` - Android Firebase config (secrets are in .env instead)

### Files safe to commit:
- `.env.example` - Template with placeholder values
- `lib/core/config/firebase_options_dev.dart` - Reads from .env, no hardcoded secrets
- `ios/Runner/Info.plist` - Contains URL scheme but no secrets

## Troubleshooting

### Firebase initialization fails
- Make sure you've created and filled in your `.env` file
- Verify all required variables are set (especially API_KEY, APP_ID, MESSAGING_SENDER_ID, PROJECT_ID)
- Check that the values match your Firebase project exactly

### Google Sign-In crashes or fails
- Verify `IOS_CLIENT_ID` is set correctly in `.env`
- Make sure the URL scheme in `Info.plist` matches your REVERSED_CLIENT_ID
- Enable Google Sign-In in Firebase Console: Authentication > Sign-in method > Google

### "Configuration missing" errors
The app will throw helpful error messages if required environment variables are missing. Check the error message to see which variables need to be added to your `.env` file.

## Team Collaboration

When a new developer joins:
1. They should copy `.env.example` to `.env`
2. Get the actual Firebase credentials from your team's secure password manager
3. Fill in their `.env` file with the real values
4. Never commit their `.env` file to git

### 4. Deploy Firebase Security Rules

After setting up your Firebase project, deploy the security rules using the provided script:

```bash
# Make sure you're in the project root directory
./deploy_firebase_rules.sh
```

Or deploy manually:

```bash
# Install Firebase CLI (if not already installed)
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project (select Firestore and Storage when prompted)
firebase init

# Deploy security rules
firebase deploy --only firestore:rules,storage
```

#### Security Rules Overview

The security rules ensure that:

**Firestore Rules (`firestore.rules`):**
- Users can only access their own data under `users/{userId}/` paths
- Projects: `users/{userId}/projects/{projectId}`
- Thoughts: `users/{userId}/projects/{projectId}/thoughts/{thoughtId}`
- Contexts: `users/{userId}/projects/{projectId}/contexts/{contextId}`
- Outputs: `users/{userId}/projects/{projectId}/outputs/{outputId}`

**Storage Rules (`storage.rules`):**
- Audio files are stored securely under `audio/{userId}/` paths
- Only authenticated users can access their own files

**Key Security Features:**
- ✅ Authentication required for all operations
- ✅ User-scoped data access (users can only see their own data)
- ✅ Hierarchical permission checks for nested collections
- ✅ Secure file storage with user-based paths

## Additional Resources

- [Firebase Setup Documentation](https://firebase.google.com/docs/flutter/setup)
- [Google Sign-In for iOS Setup](https://developers.google.com/identity/sign-in/ios/start-integrating)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase Storage Security Rules](https://firebase.google.com/docs/storage/security/start)
