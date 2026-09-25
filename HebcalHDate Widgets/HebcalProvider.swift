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

    // What the Parsha widget should actually show for today:
    // - on a Shabbat with a regular weekly reading, that parsha, even if
    //   the day is also a special Shabbat or Rosh Chodesh;
    // - otherwise, if today itself is a holiday (e.g. Yom Kippur, or Rosh
    //   Chodesh on a weekday), the holiday name;
    // - otherwise the upcoming Shabbat's parsha, or the holiday that
    //   displaces it (e.g. "Sukkot").
    let parshaShowsHoliday: Bool    // true when a holiday of today replaces the parsha
    let parshaParts: [String]       // 1 or 2 elements for stacked layouts
    let parshaPrefixed: String      // "Parashat Behar-Bechukotai", or the holiday name on a holiday
    let parshaShort: String         // "Behar-Bechukotai", or the abbreviated holiday name

    // Holiday for the rectangular (rich) widget: today's holiday if any,
    // else the upcoming Shabbat's special-Shabbat name (e.g. "Shabbat
    // Shuva" all week long). Not strictly today's — see parshaShowsHoliday.
    let richHoliday: String?
    let richHolidayShort: String?
    // Header tiers for the rectangular widget, widest to narrowest (each
    // with the holiday emoji, if any).
    let richHeaderLong: String      // "26 Tishrei 5787"
    let richHeaderShort: String     // "26 Tishrei" (no year)
    let richHeaderAbbrev: String    // "26 Tishr" (monthAbbrev)
    let omerToday: String?

    // Inline (one-line) form, replaces utilitarian-large. Tiers from
    // widest to narrowest; the view picks the first one that fits.
    let inlineText: String          // "26 Tishrei · Bereshit"
    let inlineAbbrevText: String    // "26 Tishr · Bereshit" (monthAbbrev)
    let inlineTinyText: String      // "26 Tish · Bereshit" (monthAbbrevTiny)
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
        let monthKey = tableKey(monthName)
        let monthShort = (monthAbbrev[monthKey] ?? nil) ?? monthName

        let lang = settings.lg
        let isHebrew = lang == .he

        // Parsha (independent of holiday)
        let parshaName = settings.getParshaString(hdate: hdate, fallbackToHoliday: false)
        let parshaParts = parshaName.map { splitParsha(parsha: $0) } ?? []
        let parshaForFallback = settings.getParshaString(hdate: hdate)
        let parshaPrefix = lookupTranslation(str: "Parashat", lang: lang)
        let parshaPrefixed = "\(parshaPrefix) \(parshaForFallback)"

        // Today's own holiday (specialShabbat: false, so a weekday before a
        // special Shabbat doesn't pick up "Sh. Shuva"), shown instead of the
        // parsha by the inline and Parsha widgets — except on a Shabbat with
        // a regular reading (Shabbat Shuva, Shabbat Rosh Chodesh), which
        // keeps its parsha.
        let isShabbatWithParsha = hdate.dow() == .SAT && parshaName != nil
        let holidayEvToday = isShabbatWithParsha ? nil
            : settings.pickHolidayToDisplay(hdate: hdate, specialShabbat: false)
        let holidayTodayName = holidayEvToday.map { settings.translateHolidayName(ev: $0, abbrev: false) }
        let holidayTodayShort = holidayEvToday.map { settings.translateHolidayName(ev: $0, abbrev: true) }

        // Inline / utilitarian-large equivalent.
        let inlineExtra = holidayTodayShort ?? parshaName
        let inlineFormat = isHebrew ? largeFlatFormatRTL : largeFlatFormatLTR
        func inline(_ hebDate: String) -> String {
            guard let extra = inlineExtra else { return hebDate }
            return String(format: inlineFormat, hebDate, extra)
        }
        let inlineText = inline(hebDateShort)
        let hebDateAbbrev = "\(dayNum) \(monthShort)"
        let inlineAbbrevText = inline(hebDateAbbrev)
        let inlineTinyText = inline("\(dayNum) \(monthAbbrevTiny[monthKey] ?? monthShort)")

        // Rich (rectangular) — specialShabbat: true, with emoji on the header.
        let holidayEvRich = settings.pickHolidayToDisplay(hdate: hdate, specialShabbat: true)
        var richHeaderLong = hebDateLong
        var richHeaderShort = hebDateShort
        var richHeaderAbbrev = hebDateAbbrev
        var richHoliday: String? = nil
        var richHolidayShort: String? = nil
        if let ev = holidayEvRich {
            richHoliday = settings.translateHolidayName(ev: ev, abbrev: false)
            richHolidayShort = settings.translateHolidayName(ev: ev, abbrev: true)
            if let emoji = settings.pickEmoji(events: [ev]) {
                richHeaderLong += " " + emoji
                richHeaderShort += " " + emoji
                richHeaderAbbrev += " " + emoji
            }
        }
        let omer = settings.omerStr(hdate: hdate)
        // The Parsha widget shows the holiday name instead of the weekly
        // parsha when today itself is a holiday (e.g. Yom Kippur) — showing
        // "Parashat Sukkot" (the upcoming Shabbat) on a non-Shabbat holiday
        // reads as a mistake, since it's not today's parsha. See
        // holidayEvToday for the Shabbat exception.
        let parshaWidgetParts = holidayTodayShort.map { splitParsha(parsha: $0) }
            ?? (parshaParts.isEmpty ? [parshaForFallback] : parshaParts)
        let parshaWidgetPrefixed = holidayTodayName ?? parshaPrefixed

        return HebcalEntry(
            date: date,
            hebDayNumber: dayNum,
            hebMonthName: monthName,
            hebDateShort: hebDateShort,
            hebDateLong: hebDateLong,
            hebMonthAbbrev: monthShort,
            parshaName: parshaName,
            parshaForFallback: parshaForFallback,
            parshaShowsHoliday: holidayEvToday != nil,
            parshaParts: parshaWidgetParts,
            parshaPrefixed: parshaWidgetPrefixed,
            parshaShort: holidayTodayShort ?? parshaForFallback,
            richHoliday: richHoliday,
            richHolidayShort: richHolidayShort,
            richHeaderLong: richHeaderLong,
            richHeaderShort: richHeaderShort,
            richHeaderAbbrev: richHeaderAbbrev,
            omerToday: omer,
            inlineText: inlineText,
            inlineAbbrevText: inlineAbbrevText,
            inlineTinyText: inlineTinyText
        )
    }
}
