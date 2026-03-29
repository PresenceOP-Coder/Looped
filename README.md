# Looped - Habit Tracker

Build consistency, not just motivation.
Looped is an offline-first Flutter habit tracker that helps you plan routines, stay accountable with alarms, and understand your progress through rich analytics.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![State Management](https://img.shields.io/badge/State-Riverpod-0EA5E9)](https://riverpod.dev)
[![Storage](https://img.shields.io/badge/Storage-Hive-F59E0B)](https://pub.dev/packages/hive)

## Why Looped

Most habit apps stop at checklists.
Looped adds accountability and resilience:

- Smart scheduling for daily, weekly, and custom routines
- Deadline alarms that ring until you stop them
- Streak freeze system to recover from occasional misses
- Visual analytics to highlight consistency trends
- Clean, modern UI with light, dark, and system themes
- Fully local data storage for speed and privacy

## Core Features

- Habit creation with name, description, category, frequency, reminders, and deadlines
- Category filtering for Health, Growth, Mindset, Work, and more
- Reorder habits with drag-and-drop
- Swipe-to-delete with quick feedback
- Daily progress metrics on the home screen
- Analytics dashboards including:
	- Weekly bar charts
	- Category donut chart
	- Heatmap calendar
	- Streak leaderboard
	- Best-day insights
- Onboarding flow for first-time users
- JSON data export and full reset from settings
- Alarm reliability helpers:
	- Exact alarm permission checks
	- Battery optimization exemption flow
	- App settings deep link

## Tech Stack

- Flutter
- Dart
- Riverpod
- Hive
- SharedPreferences
- Flutter Local Notifications
- Android Alarm Manager Plus
- FL Chart

## Project Structure

- [lib/main.dart](lib/main.dart) app bootstrap, initialization, routing
- [lib/core](lib/core) services, constants, themes, alarm prompt logic
- [lib/features/habits](lib/features/habits) habit domain, providers, screens, widgets
- [lib/features/analytics](lib/features/analytics) analytics providers and visual components
- [lib/features/onboarding](lib/features/onboarding) first-run onboarding flow
- [lib/features/settings](lib/features/settings) preferences, data tools, permission actions

## Getting Started

### 1) Prerequisites

- Flutter SDK installed
- Android Studio or VS Code with Flutter extension
- Android emulator or physical device

### 2) Install dependencies

Run:

```bash
flutter pub get
```

### 3) Generate model adapters (if needed)

Run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4) Launch the app

Run:

```bash
flutter run
```

## Android Notes

For deadline alarms to work reliably, allow:

- Exact alarms permission
- Ignore battery optimizations

You can enable both from the in-app Settings screen.

## Data and Privacy

- Data is stored locally on device using Hive
- No remote sync is required for core functionality
- Export tool available in Settings for backup

## Roadmap Ideas

- Cloud sync and account support
- Habit templates
- Smarter nudges and adaptive reminders
- Monthly challenge mode
- Advanced streak insights

## Contributing

Pull requests and ideas are welcome.
If you find a bug or want a feature, open an issue with clear reproduction steps and expected behavior.

## License

Add your preferred license here, for example MIT.
