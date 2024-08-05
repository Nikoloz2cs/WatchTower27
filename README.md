# WatchTower27

WatchTower27 is an iOS application that allows users to report parking officer sightings in specific parking lots. The app uses Firebase for authentication and data storage, and integrates with Apple Maps to display parking lot locations and reports.

## Features

- **User Authentication**: Users can sign up and log in using their email addresses.
- **Email Verification**: Ensures users verify their email addresses before using the app.
- **Parking Lot Reporting**: Users can report sightings in parking lots, which are visible on the map.
- **Cooldown Timer**: Users can report once every 5 minutes.
- **Out of Bounds Detection**: Alerts users if they are out of the campus bounds.
- **Firebase Integration**: Uses Firebase for authentication, Firestore for data storage, and Cloud Functions for scheduled tasks.

## Requirements

- Xcode 12.0 or later
- iOS 14.0 or later
- CocoaPods
- Firebase account
- This repo is missing my "firebase-admin-setup" file as well as the "GoogleService-Info.plist" file, therefore you'll have quite a lot of trouble just copying the repo. On the bright side, the Swift side of things is all here.
