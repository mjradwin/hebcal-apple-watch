//
//  HebcalProvider.swift
//  HebcalHDate Widgets
//
//  TimelineProvider that produces sparse entries pegged to the
//  moments when the rendered text might change (mainly 8pm local,
//  when the Hebrew day rolls over).
//

import Foundation
import WidgetKit
import Hebcal

struct HebcalEntry: TimelineEntry {
    let date: Date

    // Hebrew date pieces (already localised / transliterated for the
    // current user setting).
    let hebDayNumber: String        // "26" or "כ״ו"
    let hebMonthName: String        // "Iyyar" or "אייר"
    let hebDateShort: String        // "26 Iyyar"
    let hebDateLong: String         // "26 Iyyar 5785"
    let hebMonthAbbrev: String      // best-fit short month for circular faces

    // Parsha
    let parshaName: String?         // "Behar-Bechukotai"
    let parshaForFallback: String

    // What the Parsha widget should actually show for today: the weekly
    // parsha, UNLESS today itself is a holiday (e.g. Yom Kippur), in which
    // case the holiday name takes over so the widget doesn't show a
    // confusing "upcoming Shabbat" parsha on a day that isn't Shabbat.
    let parshaParts: [String]       // 1 or 2 elements for stacked layouts
    let parshaPrefixed: String      // "Parashat Behar-Bechukotai", or the holiday name on a holiday

    // Holiday picked for this date (specialShabbat included for the rich widget).
    let holidayToday: String?
    let holidayShort: String?
    let richHeaderLong: String      // header for rectangular widget (with year + emoji)
    let richHeaderShort: String     // shorter version (no year, with emoji)
    let omerToday: String?

    // Inline (one-line) form, replaces utilitarian-large. Tiers from
    // widest to narrowest; the view picks the first one that fits.
    let inlineLongText: String      // "26 Tishrei 5787 · Bereshit"
    let inlineText: String          // "26 Tishrei · Bereshit"
    let inlineAbbrevText: String    // "26 Tishr · Bereshit" (monthAbbrev)
    let inlineTinyText: String      // "26 Tish · Bereshit" (monthAbbrevTiny)

    let isHebrew: Bool
}

struct HebcalProvider: TimelineProvider {
    typealias Entry = HebcalEntry

    func placeholder(in context: Context) -> HebcalEntry {
        return HebcalProvider.makeEntry(for: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (HebcalEntry) -> Void) {
        completion(HebcalProvider.makeEntry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HebcalEntry>) -> Void) {
        let now = Date()
        let dates = HebcalProvider.makeTimelineDates(date: now)
        let entries = dates.map { HebcalProvider.makeEntry(for: $0) }
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    // MARK: - Timeline pivots

    private static let fourHours = 4.0 * 60.0 * 60.0

    // Mirrors the legacy ComplicationController.makeTimelineDates so
    // the text rolls over at 8pm local time (when ModelData.makeHDate
    // advances to the next Hebrew day) and again at midnight.
    static func makeTimelineDates(date: Date) -> [Date] {
        var gregCalendar = Calendar(identifier: .gregorian)
        gregCalendar.timeZone = .autoupdatingCurrent
        let dateComponents = gregCalendar.dateComponents([.hour], from: date)
        let hour = dateComponents.hour!
        if hour < 2 {
            let oneFiftyNine = gregCalendar.date(bySettingHour: 1, minute: 59, second: 59, of: date)!
            return [date, oneFiftyNine]
        } else if hour < 10 {
            let tenAm = gregCalendar.date(bySettingHour: 10, minute: 0, second: 0, of: date)!
            return [date, tenAm]
        } else if hour < 20 {
            let sevenFiftyNine = gregCalendar.date(bySettingHour: 19, minute: 59, second: 0, of: date)!
            let eightPm = sevenFiftyNine.addingTimeInterval(60.0)
            let elevenFiftyNine = sevenFiftyNine.addingTimeInterval(fourHours)
            return [date, sevenFiftyNine, eightPm, elevenFiftyNine]
        } else {
            let elevenFiftyNine = gregCalendar.date(bySettingHour: 23, minute: 59, second: 0, of: date)!
            let oneFiftyNineAm = elevenFiftyNine.addingTimeInterval(fourHours)
            return [date, elevenFiftyNine, oneFiftyNineAm]
        }
    }

    // MARK: - Entry construction

    private static let largeFlatFormatRTL = "\u{202E}%@ · %@"
    private static let largeFlatFormatLTR = "%@ · %@"

    static func makeEntry(for date: Date) -> HebcalEntry {
        let settings = ModelData.shared
        // The widget process reuses ModelData.shared across reloads, so
        // pick up any setting the app changed since this process started.
        settings.refreshFromDefaults()
        let hdate = settings.makeHDate(date: date)

        let parts = settings.getHebDateStringParts(hdate: hdate, showYear: false)
        let dayNum = parts[0]
        let monthName = parts[1]
        let hebDateShort = parts.joined(separator: " ")
        let hebDateLong = settings.getHebDateString(hdate: hdate, showYear: true)
        let monthShort = (monthAbbrev[monthName] ?? nil) ?? monthName

        let lang = settings.lg
        let isHebrew = lang == .he

        // Parsha (independent of holiday)
        let parshaName = settings.getParshaString(hdate: hdate, fallbackToHoliday: false, heNikud: false)
        let parshaParts = parshaName.map { splitParsha(parsha: $0) } ?? []
        let parshaForFallback = settings.getParshaString(hdate: hdate, heNikud: false)
        let parshaPrefix = lookupTranslation(str: "Parashat", lang: lang)
        let parshaPrefixed = "\(parshaPrefix) \(parshaForFallback)"

        // Inline / utilitarian-large equivalent (specialShabbat: false).
        let holidayEvForInline = settings.pickHolidayToDisplay(hdate: hdate, specialShabbat: false)
        let holidayInlineAbbrev = holidayEvForInline.map { settings.translateHolidayName(ev: $0, abbrev: true) }
        let inlineExtra = holidayInlineAbbrev ?? parshaName
        let inlineFormat = isHebrew ? largeFlatFormatRTL : largeFlatFormatLTR
        func inline(_ hebDate: String) -> String {
            guard let extra = inlineExtra else { return hebDate }
            return String(format: inlineFormat, hebDate, extra)
        }
        let inlineLongText = inline(hebDateLong)
        let inlineText = inline(hebDateShort)
        let inlineAbbrevText = inline("\(dayNum) \(monthShort)")
        let inlineTinyText = inline("\(dayNum) \(monthAbbrevTiny[monthName] ?? monthShort)")

        // Rich (rectangular) — specialShabbat: true, with emoji on the header.
        let holidayEvRich = settings.pickHolidayToDisplay(hdate: hdate, specialShabbat: true)
        var richHeaderLong = hebDateLong
        var richHeaderShort = hebDateShort
        var holidayToday: String? = nil
        var holidayShort: String? = nil
        if let ev = holidayEvRich {
            holidayToday = settings.translateHolidayName(ev: ev, abbrev: false)
            holidayShort = settings.translateHolidayName(ev: ev, abbrev: true)
            if let emoji = settings.pickEmoji(events: [ev]) {
                richHeaderLong += " " + emoji
                richHeaderShort += " " + emoji
            }
        }
        let omer = settings.omerStr(hdate: hdate)
        // The Parsha widget shows the holiday name instead of the weekly
        // parsha when today itself is a holiday (e.g. Yom Kippur) — showing
        // "Parashat Sukkot" (the upcoming Shabbat) on a non-Shabbat holiday
        // reads as a mistake, since it's not today's parsha.
        let parshaWidgetParts = holidayToday.map { splitParsha(parsha: holidayShort ?? $0) }
            ?? (parshaParts.isEmpty ? [parshaForFallback] : parshaParts)
        let parshaWidgetPrefixed = holidayToday ?? parshaPrefixed

        return HebcalEntry(
            date: date,
            hebDayNumber: dayNum,
            hebMonthName: monthName,
            hebDateShort: hebDateShort,
            hebDateLong: hebDateLong,
            hebMonthAbbrev: monthShort,
            parshaName: parshaName,
            parshaForFallback: parshaForFallback,
            parshaParts: parshaWidgetParts,
            parshaPrefixed: parshaWidgetPrefixed,
            holidayToday: holidayToday,
            holidayShort: holidayShort,
            richHeaderLong: richHeaderLong,
            richHeaderShort: richHeaderShort,
            omerToday: omer,
            inlineLongText: inlineLongText,
            inlineText: inlineText,
            inlineAbbrevText: inlineAbbrevText,
            inlineTinyText: inlineTinyText,
            isHebrew: isHebrew
        )
    }
}
