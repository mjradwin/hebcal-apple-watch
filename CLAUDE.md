# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Apple Watch (watchOS) app for the Hebrew calendar: shows today's Hebrew date, upcoming holidays, and the weekly Torah portion, plus watch face complications. Distributed via the App Store and TestFlight. There is no companion iPhone app — the iPhone target is the required stub that ships the watch app.

- Deployment targets: watchOS 7.6 / iOS 13.1.
- Swift Package dependency: [`hebcal-swift`](https://github.com/hebcal/hebcal-swift) (`Hebcal` module, tracks the `main` branch). All Jewish calendar math — HDate, Sedra, holidays, daf yomi, translations, Hebrew numerals — comes from this package.

## Build / run

This is an Xcode project (`HebcalHDate.xcodeproj`); there is no SwiftPM/CocoaPods/fastlane setup and no test target. Normal workflow is to open the project in Xcode and build/run on the watchOS simulator or a paired device.

Command-line builds (rarely needed):

```sh
xcodebuild -project HebcalHDate.xcodeproj \
  -scheme "HebcalHDate WatchKit App" \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' \
  build
```

Swift package resolution: `xcodebuild -resolvePackageDependencies` if package state gets wedged.

## Architecture

Three Xcode targets, but essentially all code lives in the **WatchKit Extension**:

- `HebcalHDate` — iPhone stub (required by App Store, no UI code of interest).
- `HebcalHDate WatchKit App` — watch app shell (storyboard/assets only).
- `HebcalHDate WatchKit Extension` — all Swift sources.

### Single source of truth: `ModelData`

`ModelData.swift` is a `@StateObject` singleton (`ModelData.shared`) that owns app state and is shared between the SwiftUI views *and* the complication data source. Three `@Published` user settings — `il` (Israel vs Diaspora schedule), `lang` (Sephardic / Ashkenazi / Hebrew transliteration), `dafyomi` — persist to `UserDefaults` and, on change, invalidate caches and call `CLKComplicationServer.reloadTimeline` for every active complication. Mutating these from anywhere automatically refreshes the watch face.

Two caches keyed by Hebrew year: `yearCache` (holiday events) and `sedraCache` (Torah portion schedule). These are cleared when `il` changes because the Israel/Diaspora schedules diverge.

`updateDateItems()` rebuilds the date list when the Gregorian day changes. It produces `todayDateItem` plus a `dateItems` array covering: every day for ~2 weeks, then only Shabbatot and holidays for ~4 months out. The "today" calculation in `makeHDate(date:)` rolls over to the next Hebrew date after 8 PM local time, since Hebrew days start at sundown — keep this in mind when changing date logic.

### Views

`ContentView` is the root and reacts to `scenePhase`: on `.active` it refreshes date items; on `.background` it schedules a `WKApplicationRefreshBackgroundTask`. `TodayView` renders one `DateItem` and is reused both for the top of the main screen and inside the scrolling `HDateList`. `SettingsView` mutates `ModelData` directly via `@EnvironmentObject` bindings.

### Complications

`ComplicationController.swift` is the largest file in the project (~600 lines) and exposes three complication descriptors: `complicationHebcal` (large families), `complicationHdate` (small/corner), `complicationParsha` (small). Timeline entries are sparse — `makeTimelineDates` returns only the date plus a few transition points (notably 8 PM, when "today's" Hebrew date rolls over). Two large dictionaries at the top — `monthAbbrev`/`monthAbbrevTiny` and `parshaHyphenate` — provide pixel-budgeted abbreviations for each watch face family. When a new parsha string or month name doesn't fit on a particular face, the fix usually goes in those tables, not in layout code.

### Background refresh

`ExtensionDelegate` schedules a background refresh every 2 hours; on wake it calls `checkTimeZone()` (forces a complication reload if the device travelled across time zones) and `updateDateItems()`.

### Localization

`en.lproj`, `en-AU.lproj`, `en-GB.lproj`, `en-IN.lproj`, `he.lproj` contain `Localizable.strings`. User-visible holiday/parsha translations come from the `Hebcal` package's `lookupTranslation(str:lang:)`, not the `.lproj` files — those are only for app chrome (button labels, section headers).

## Conventions worth knowing

- `TranslationLang` enum from the Hebcal package has cases `.en` (Sephardic), `.ashkenazi`, `.he`, `.heNikud`. UI exposes the first three; `.heNikud` is used internally for the parsha complication where vowel points are wanted.
- Hebrew (`lg == .he`) renders right-aligned — many views branch on `isHebrew` to flip alignment / insert `Spacer`s.
- Holiday abbreviations (`holidayAbbrev` in `ModelData`) and Chanukah emoji renderings are tuned for narrow complication families; changing them affects what shows on the watch face.
