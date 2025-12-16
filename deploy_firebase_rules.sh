#!/bin/bash

# Deploy Firebase Security Rules
# This script deploys Firestore and Storage security rules to Firebase

echo "🚀 Deploying Firebase Security Rules..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    echo "❌ Not logged in to Firebase. Please login first:"
    echo "firebase login"
    exit 1
fi

# Deploy rules
echo "📋 Deploying Firestore rules..."
firebase deploy --only firestore:rules

if [ $? -eq 0 ]; then
    echo "✅ Firestore rules deployed successfully!"
else
    echo "❌ Failed to deploy Firestore rules"
    exit 1
fi

echo "📦 Deploying Storage rules..."
firebase deploy --only storage

if [ $? -eq 0 ]; then
    echo "✅ Storage rules deployed successfully!"
else
    echo "❌ Failed to deploy Storage rules"
    exit 1
fi

echo ""
echo "🎉 All Firebase Security Rules deployed successfully!"
echo ""
echo "Your app should now be able to:"
echo "✅ Create and read projects"
echo "✅ Add text and audio thoughts"
echo "✅ Refine contexts and generate outputs"
echo "✅ Upload audio files securely"
echo ""
echo "If you still see permission errors, make sure:"
echo "1. Users are properly authenticated"
echo "2. The Firebase project ID in your .env matches this deployment"
echo "3. Rules were deployed to the correct Firebase project"

