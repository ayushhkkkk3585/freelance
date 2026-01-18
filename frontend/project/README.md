# TicketBook - Flutter Mobile App

A modern Flutter mobile application for ticket booking with Client and Buyer roles.

## Features

- 🎨 **Modern UI** - Red/white theme with Material 3
- 👥 **Role-based Access** - Client and Buyer roles
- 💰 **Point System** - Virtual wallet with ₹1 = 1 point
- ⏱️ **Booking Timer** - 5-minute countdown for buyers
- 💬 **Chat Feature** - In-app messaging
- 🔔 **Notifications** - Real-time updates
- ⭐ **Reviews** - Rate completed bookings

## Getting Started

### Prerequisites

- Flutter SDK 3.4+
- Dart 3.4+

### Installation

1. Navigate to the project folder:
```bash
cd frontend/project
```

2. Install dependencies:
```bash
flutter pub get
```

3. Update API URL in `lib/core/constants/app_constants.dart`:
```dart
static const String baseUrl = 'http://YOUR_SERVER_IP:3000/api';
```

4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── core/
│   ├── constants/           # App constants
│   ├── routes/              # Navigation routes
│   └── theme/               # App theme
├── models/                  # Data models
├── providers/               # State management
├── services/                # API services
└── screens/
    ├── auth/               # Login & Register
    ├── splash/             # Splash screen
    ├── home/               # Home with navigation
    ├── client/             # Client dashboard & create request
    ├── buyer/              # Buyer dashboard & request detail
    ├── profile/            # User profile
    ├── notifications/      # Notifications list
    ├── chat/               # Chat screen
    └── widgets/            # Reusable widgets
```

## User Flows

### Client Flow
1. Register/Login as Client
2. View wallet balance and request history
3. Create new event request with details
4. Receive notifications on request status
5. View ticket screenshot when completed

### Buyer Flow
1. Register/Login as Buyer
2. Browse available requests by category
3. Accept request to start 5-minute timer
4. Upload ticket screenshot to complete
5. Earn points on successful completion

## Categories

- 🎬 Movies
- 🎭 Events
- ⚽ Sports
- 📺 Live Events
- 🎵 Music
- 🛍️ Shopping
- 🍔 Food & Beverages
- ✈️ Booking

## Dependencies

- `provider` - State management
- `http` - API calls
- `shared_preferences` - Local storage
- `image_picker` - Screenshot upload
- `intl` - Date formatting
