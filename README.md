# 📍 NearFix

**On-Demand Local Service Booking App** — built with Flutter & Supabase

NearFix connects customers with verified local service providers — electricians, plumbers, technicians, and more — in just a few taps. Discover nearby providers on an interactive map, compare ratings and pricing, book a visit, and pay securely in-app. Real-time chat keeps you connected with your provider from booking to job completion.

---

## ✨ Features

- 🗺️ **Map-Based Provider Discovery** — find nearby service providers using your live location or a manually dropped pin
- 👤 **Provider Profiles** — view ratings, visiting charges, and service details before booking
- 📅 **Instant Scheduling** — pick a service, choose a time, and confirm in seconds
- 💳 **Secure In-App Payments** — integrated Razorpay checkout
- 📋 **Booking Management** — track upcoming and past bookings, view full booking details
- 💬 **Real-Time Chat** — message your assigned provider directly within the app
- 🤖 **AI Support Chatbot** — instant answers to common questions
- 🏠 **Saved Addresses** — manage multiple service locations
- 🔔 **Push Notifications** — booking updates, chat messages, and reminders
- 🔐 **OTP-Based Authentication** — secure sign-up, sign-in, and password recovery
- 🌓 **Guided Onboarding** — smooth first-time user experience

---

## 🛠️ Tech Stack

| Category | Technology |
|---|---|
| Framework | Flutter |
| Backend / Database | Supabase (real-time) |
| Payments | Razorpay |
| Maps | flutter_map + latlong2 |
| Local Storage | shared_preferences |
| Networking | http |
| Other | url_launcher, AI chatbot service |

---

## 📱 Screenshots

<!-- Add app screenshots here -->
| Home | Provider Selection | Booking | Chat |
|---|---|---|---|
| _screenshot_ | _screenshot_ | _screenshot_ | _screenshot_ |

---

## 🏗️ Project Structure

```
lib/
├── onboarding_screen/       # First-launch onboarding flow
├── authentication/          # Sign in, sign up, OTP, password reset
├── home_screen/             # Main dashboard
├── service_providers/       # Nearby provider listing
├── service_provider_detail/ # Provider profile & details
├── map/                     # Map-based location picker
├── booking_screen/          # Scheduling, booking details & history
├── payment_screen/          # Razorpay payment flow
├── chat_screen/             # Real-time chat with provider
├── chatbot/                 # AI support chatbot
├── address_screen/          # Saved address management
├── profile_screen/          # User profile & settings
├── notifications/           # In-app notifications
├── supabase_client.dart     # Supabase initialization
└── app_config.dart          # App-wide configuration
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- A Supabase project (URL + anon key)
- A Razorpay account (for payment testing)

### Installation

```bash
git clone https://github.com/VegadManas/nearfix.git
cd nearfix
flutter pub get
```

### Configuration

Update `lib/supabase_client.dart` with your Supabase credentials:

```dart
class SupabaseConfig {
  static const String url = "YOUR_SUPABASE_URL";
  static const String anonKey = "YOUR_SUPABASE_ANON_KEY";
}
```

Update `lib/app_config.dart` with your backend base URL:

```dart
class AppConfig {
  static const String baseUrl = "YOUR_BACKEND_URL";
}
```

### Run the app

```bash
flutter run
```

---

## 🔗 Related Project

This app works alongside **[NearFix Partner](https://github.com/VegadManas/nearfix_partner)** — the companion app used by service providers to manage jobs booked through NearFix.

---



---

## 👤 Author

**Manas Vegad**
[GitHub](https://github.com/VegadManas)
