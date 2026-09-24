# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Apple Watch (watchOS) app for the Hebrew calendar: shows today's Hebrew date, upcoming holidays, and the weekly Torah portion, plus watch face complications. Distributed via the App Store and TestFlight. There is no companion iPhone app — the iPhone target is the required stub that ships the watch app.

- Deployment targets: watchOS 10.6 (watch app) / watchOS 9.0 + iOS 15.6 (widget extension) / iOS 13.1 (iPhone stub). The app was migrated to watchOS 10 (single-target watch app) and its complications from ClockKit to WidgetKit.
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

Three Xcode targets:

- `HebcalHDate` — iPhone stub (required by App Store, no UI code of interest).
- `HebcalHDate WatchKit App` — the watchOS 10 watch app. Under the single-target watchOS 10 model there is no separate extension target anymore, so this target owns all of the app's Swift sources. Those sources still live in the folder named `HebcalHDate WatchKit Extension/` (the folder name predates the migration).
- `HebcalHDate Widgets` — the WidgetKit extension that provides the watch face complications (see below). Its sources are in `HebcalHDate Widgets/`.

### Single source of truth: `ModelData`

`ModelData.swift` is an `ObservableObject` singleton (`ModelData.shared`) that owns app state. It is compiled into **both** the watch app and the widget extension, and the two processes share settings through an **App Group `UserDefaults` suite** (`ModelData.defaults`), not `UserDefaults.standard`. Three `@Published` user settings — `il` (Israel vs Diaspora schedule), `lang` (an `Int` raw value; map to `TranslationLang` via the `lg` computed property for Sephardic / Ashkenazi / Hebrew), `dafyomi` — persist to that suite and, on change, invalidate caches and call `WidgetCenter.shared.reloadAllTimelines()`. Mutating these from the app automatically refreshes the watch face.

Because the widget process keeps `ModelData.shared` alive across `getTimeline()` calls, it can hold stale settings; `refreshFromDefaults()` re-reads the App Group suite at the start of timeline generation and only mutates (and reloads) when a value actually changed.

Two caches keyed by Hebrew year: `yearCache` (holiday events) and `sedraCache` (Torah portion schedule). These are cleared when `il` changes because the Israel/Diaspora schedules diverge.

`updateDateItems()` rebuilds the date list when the Gregorian day changes. It produces `todayDateItem` plus a `dateItems` array covering: every day for ~2 weeks, then only Shabbatot and holidays for ~4 months out. The "today" calculation in `makeHDate(date:)` rolls over to the next Hebrew date after 8 PM local time, since Hebrew days start at sundown — keep this in mind when changing date logic.

### Views

`ContentView` is the root and reacts to `scenePhase`: on `.active` it refreshes date items; on `.background` it schedules a `WKApplicationRefreshBackgroundTask`. `TodayView` renders one `DateItem` and is reused both for the top of the main screen and inside the scrolling `HDateList`. `SettingsView` mutates `ModelData` directly via `@EnvironmentObject` bindings.

### Complications (WidgetKit)

Complications live in the **`HebcalHDate Widgets`** extension, split across four files:

- `HebcalWidgetBundle.swift` — the `@main WidgetBundle` and its three `StaticConfiguration` widgets: `HebcalWidget` (rectangular/inline), `HDateWidget` (circular/corner) and `ParshaWidget` (circular). Only `HebcalWidget` offers `.accessoryInline` — the Hebrew Date and Torah Portion inline variants were dropped deliberately so the inline slot shows just the combined Hebcal text; don't re-add them. Each widget's `kind` string (`complicationHebcal`, `complicationHdate`, `complicationParsha`) is **preserved verbatim from the legacy ClockKit `CLKComplicationDescriptor` identifiers** so existing faces migrate 1:1 — don't rename them. Each declares its `supportedFamilies` here.
- `HebcalProvider.swift` — the `TimelineProvider` (`HebcalProvider`) and its `HebcalEntry`. Entries are sparse: `makeTimelineDates` returns only the date plus a few transition points (notably 8 PM, when "today's" Hebrew date rolls over), and the timeline uses `.atEnd` reload policy. `makeEntry(for:)` builds all the per-family display strings.
- `HebcalWidgetViews.swift` — one SwiftUI view per family (e.g. `HDateCircularView`, `HDateCornerView`, `ParshaCircularView`, `ParshaCornerView`, `HebcalRectangularView`), plus the `*WidgetEntryView` container views that `switch` on `@Environment(\.widgetFamily)`. Note the family constraints: `.accessoryCorner` content and its `.widgetLabel` are **system-sized** — `.font(size:)` there is ignored; use `.accessoryCircular` when you need a large custom glyph.
- `WidgetTextHelpers.swift` — the `monthAbbrev`/`monthAbbrevTiny` and `parshaHyphenate` dictionaries (pixel-budgeted abbreviations per family) and the `splitParsha` helper. When a new parsha string or month name doesn't fit on a particular face, the fix usually goes in those tables, not in layout code. The tables are keyed with plain ASCII `'`, but `lookupTranslation` returns `’` for Sephardic/Ashkenazi, so look names up via `tableKey(_:)`. Ashkenazi spellings that differ (e.g. `Teves`) need their own entries.

ClockKit is otherwise gone; it survives only as the `CLKComplicationWidgetMigrator` conformance in `ExtensionDelegate.swift`, which maps each old ClockKit complication to its WidgetKit `kind` for users upgrading from the pre-migration build.

### Background refresh

`ExtensionDelegate` schedules a background refresh (roughly every 2 hours); on wake it calls `checkTimeZone()` (forces a complication reload via `WidgetCenter` if the device travelled across time zones) and `updateDateItems()`.

### Localization

`en.lproj`, `en-AU.lproj`, `en-GB.lproj`, `en-IN.lproj`, `he.lproj` contain `Localizable.strings`. User-visible holiday/parsha translations come from the `Hebcal` package's `lookupTranslation(str:lang:)`, not the `.lproj` files — those are only for app chrome (button labels, section headers).

## Conventions worth knowing

- `TranslationLang` enum from the Hebcal package has cases `.en` (Sephardic), `.ashkenazi`, `.he`, `.heNikud`. UI exposes the first three. `getParshaString(…heNikud:)` can opt into `.heNikud` (vowel points) when `lg == .he`, but every current caller passes `heNikud: false`, so vowel points are effectively unused right now.
- Hebrew (`lg == .he`) renders right-aligned — many views branch on `isHebrew` to flip alignment / insert `Spacer`s.
- Holiday abbreviations (`holidayAbbrev` in `ModelData`) and Chanukah emoji renderings are tuned for narrow complication families; changing them affects what shows on the watch face.
- Dynamic Type scaling for fixed point sizes uses SwiftUI's built-in `@ScaledMetric` property wrapper (e.g. `TodayView`'s `smallFontSize`/`largeFontSize`), not a custom `UIFontMetrics` wrapper — `@ScaledMetric` has been available since watchOS 7, well under the 10.6 floor. A prior hand-rolled `ScaledFont` view modifier was removed in favor of this.
