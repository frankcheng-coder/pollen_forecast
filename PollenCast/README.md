# PollenCast

A native iOS app that helps users view current and forecasted pollen levels for their location.

## Features (MVP)

- **Home Screen** — Current pollen risk level, weather context, 5-day forecast, pollen type breakdown, health guidance
- **Map Screen** — MapKit-based map with pollen annotations, bottom sheet with pollen details, recenter button
- **Saved Locations** — Search and save cities, tap to view their pollen data
- **Detail View** — Expanded breakdown for a specific day: pollen types, weather, outdoor rating
- **Settings** — Location permission status, units, data source attribution

## Architecture

- **MVVM** with service layer
- **SwiftUI** throughout (iOS 17+)
- Domain models separate from API DTOs
- Protocol-based services for testability
- Mock data provider for development without API keys

## Data Sources

| Source | Purpose |
|--------|---------|
| Google Pollen API | Pollen index, type breakdown, daily forecast |
| Apple WeatherKit | Temperature, humidity, wind, precipitation, conditions |
| Core Location | User coordinates, geocoding |
| MapKit | Map display, location search |

## Setup

### Prerequisites

- Xcode 16+ 
- iOS 17.0+ deployment target
- xcodegen (`brew install xcodegen`) for project generation

### 1. Clone and generate project

```bash
cd PollenCast
xcodegen generate
open PollenCast.xcodeproj
```

### 2. Configure Google Pollen API Key

1. Get an API key from [Google Cloud Console](https://console.cloud.google.com/)
2. Enable the **Pollen API** for your project
3. Edit `PollenCast/Configuration/Debug.xcconfig`:
   ```
   GOOGLE_POLLEN_API_KEY = your_actual_key_here
   ```
4. Do the same for `Release.xcconfig`

> **Note:** Without an API key, the app falls back to realistic mock data automatically.

### 3. Configure WeatherKit

1. In your Apple Developer account, enable the **WeatherKit** capability for your App ID
2. In Xcode, go to **Signing & Capabilities** → Add **WeatherKit**
3. The `PollenCast.entitlements` file already includes the `com.apple.developer.weatherkit` entitlement

> **Note:** Without WeatherKit configured, the app uses `MockWeatherService` by default. To switch to real weather data, change `MockWeatherService()` to `WeatherKitService()` in `HomeViewModel.swift` and `DetailViewModel.swift`.

### 4. Set Bundle Identifier

Update `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml` (currently `com.pollencast.app`) to match your developer account, then regenerate:

```bash
xcodegen generate
```

### 5. Location Permission

The app requests "When In Use" location permission. The permission string is configured in `Info.plist`. No additional setup needed.

## Project Structure

```
PollenCast/
├── App/                    # App entry point, ContentView with tab bar
├── Models/
│   ├── Domain/             # PollenModels, WeatherModels, LocationItem, Recommendation
│   └── DTO/                # GooglePollenDTO, WeatherKitDTO (API response mapping)
├── Services/
│   ├── LocationService     # Core Location wrapper
│   ├── PollenAPIService    # Google Pollen API client
│   ├── WeatherKitService   # Apple WeatherKit client
│   ├── CacheService        # UserDefaults-based caching + saved locations
│   ├── RecommendationEngine # Rule-based outdoor guidance
│   ├── LocationSearchService # MapKit local search
│   └── MockDataProvider    # Realistic mock data for previews/development
├── ViewModels/             # HomeVM, MapVM, SavedLocationsVM, DetailVM
├── Views/
│   ├── Home/               # HomeView + component cards
│   ├── Map/                # MapScreenView + annotations
│   ├── Locations/          # SavedLocationsView + search
│   ├── Detail/             # DetailView (expanded day/location)
│   ├── Settings/           # SettingsView
│   └── Components/         # PollenLevelBadge, LocationPermissionView, ErrorStateView
├── Utilities/              # Constants, Extensions, ColorTheme
├── Configuration/          # Debug/Release xcconfig files
└── Resources/              # Assets
```

## TODO

Items requiring your credentials or developer setup:

- [ ] Add your Google Pollen API key to xcconfig files
- [ ] Enable WeatherKit in Apple Developer portal
- [ ] Switch from `MockWeatherService` to `WeatherKitService` after WeatherKit setup
- [ ] Update bundle identifier to your own
- [ ] Add app icons to Assets.xcassets
- [ ] Test with real location permissions on a device

## Future Enhancements (Out of MVP Scope)

- Push notifications for daily pollen alerts
- WidgetKit home screen widget
- Pollen heatmap overlay on map
- Historical pollen trends
- Apple Watch companion
- User accounts and sync
