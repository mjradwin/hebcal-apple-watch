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
    let parshaParts: [String]       // 1 or 2 elements for stacked layouts
    let parshaPrefixed: String      // "Parashat Behar-Bechukotai" (always set)

    // Holiday picked for this date (specialShabbat included for the rich widget).
    let richHeaderLong: String      // header for rectangular widget (with year + emoji)
    let richHeaderShort: String     // shorter version (no year, with emoji)
    let richBody1: String           // holiday-today OR parsha
    let richBody2: String?          // parsha OR omer (may be nil)

    // Inline (one-line) form, replaces utilitarian-large.
    let inlineText: String
    let inlineShortText: String?

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
        let inlineText: String
        if let extra = inlineExtra {
            inlineText = String(format: inlineFormat, hebDateShort, extra)
        } else {
            inlineText = hebDateShort
        }
        var inlineShort: String? = nil
        if let extra = inlineExtra, let abbrev = monthAbbrev[monthName] ?? nil {
            inlineShort = String(format: inlineFormat, "\(dayNum) \(abbrev)", extra)
        }

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
        let richBody1 = holidayToday ?? (parshaName ?? parshaForFallback)
        let richBody2: String?
        if holidayToday != nil {
            richBody2 = parshaName
        } else {
            richBody2 = omer
        }
        _ = holidayShort  // currently unused; preserved for future short layouts

        return HebcalEntry(
            date: date,
            hebDayNumber: dayNum,
            hebMonthName: monthName,
            hebDateShort: hebDateShort,
            hebDateLong: hebDateLong,
            hebMonthAbbrev: monthShort,
            parshaName: parshaName,
            parshaParts: parshaParts.isEmpty ? [parshaForFallback] : parshaParts,
            parshaPrefixed: parshaPrefixed,
            richHeaderLong: richHeaderLong,
            richHeaderShort: richHeaderShort,
            richBody1: richBody1,
            richBody2: richBody2,
            inlineText: inlineText,
            inlineShortText: inlineShort,
            isHebrew: isHebrew
        )
    }
}
