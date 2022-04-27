//
//  ModelData.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 8/23/21.
//

import Foundation
import Combine
import os
import Hebcal
import ClockKit

final class ModelData: ObservableObject {
    let logger = Logger(
        subsystem: "com.hebcal.HebcalHDate.watchkitapp.watchkitextension.ModelData",
        category: "Model")

    // The data model needs to be accessed both from the app extension
    // and from the complication controller.
    static let shared = ModelData()

    private func reloadComplications() -> Void {
        // Update any complications on active watch faces.
        let server = CLKComplicationServer.sharedInstance()
        for complication in server.activeComplications ?? [] {
            logger.debug("reloadTimeline for \(complication.identifier) il=\(self.il) lang=\(self.lang)")
            server.reloadTimeline(for: complication)
        }
    }

    @Published public var il: Bool {
        didSet {
            if !doingInit {
                logger.debug("il=\(self.il)")
                UserDefaults.standard.set(il, forKey: "israel")
                sedraCache = [:]
                currentDay = -1
                updateDateItems()
                reloadComplications()
            }
        }
    }

    @Published public var lang: Int {
        didSet {
            if !doingInit {
                logger.debug("lang=\(self.lang)")
                UserDefaults.standard.set(lang, forKey: "lang")
                currentDay = -1
                updateDateItems()
                reloadComplications()
            }
        }
    }

    public var lg: TranslationLang {
        TranslationLang(rawValue: self.lang) ?? TranslationLang.en
    }

    private let gregCalendar = Calendar.autoupdatingCurrent
    public func makeHDate(date: Date) -> HDate {
        var hdate = HDate(date: date)
        let hour = gregCalendar.dateComponents([.hour], from: date).hour!
        if (hour > 19) {
            hdate = hdate.next()
        }
        return hdate
        // return HDate(yy: 5795, mm: .TISHREI, dd: 8)
    }

    public func getHebDateString(date: Date, showYear: Bool) -> String {
        let hdate = makeHDate(date: date)
        return self.getHebDateString(hdate: hdate, showYear: showYear)
    }

    public func getHebDateString(hdate: HDate, showYear: Bool) -> String {
        let parts = getHebDateStringParts(hdate: hdate, showYear: showYear)
        return parts.joined(separator: " ")
    }

    public func getHebDateStringParts(date: Date, showYear: Bool) -> [String] {
        let hdate = makeHDate(date: date)
        return self.getHebDateStringParts(hdate: hdate, showYear: showYear)
    }

    public func getHebDateStringParts(hdate: HDate, showYear: Bool) -> [String] {
        var parts = [String]()
        let isHebrew = lg == .he
        let day = isHebrew ? hebnumToString(number: hdate.dd) : String(hdate.dd)
        parts.append(day)
        parts.append(lookupTranslation(str: hdate.monthName(), lang: lg))
        if showYear {
            let year = isHebrew ? hebnumToString(number: hdate.yy) : String(hdate.yy)
            parts.append(year)
        }
        return parts
    }

    public func getHolidayNameForParsha(hdate: HDate) -> String {
        let abs = dayOnOrBefore(dayOfWeek: DayOfWeek.SAT, absdate: hdate.abs() + 6)
        let hd = HDate(absdate: abs)
        if (hd.mm == .TISHREI) {
            switch hd.dd {
            case 1: return "Rosh Hashana"
            case 10: return "Yom Kippur"
            case 15, 16, 17, 18, 19, 20, 21: return "Sukkot"
            case 22: return "Shmini Atzeret"
            default: return "??"
            }
        } else if (hd.mm == .NISAN) {
            return "Pesach"
        } else if (hd.mm == .SIVAN) {
            return "Shavuot"
        } else {
            return "??"
        }
    }

    public func getParshaString(date: Date, heNikud: Bool) -> String {
        let hdate = makeHDate(date: date)
        return self.getParshaString(hdate: hdate, heNikud: heNikud)
    }

    public func getParshaString(hdate: HDate, heNikud: Bool) -> String {
        return self.getParshaString(hdate: hdate, fallbackToHoliday: true, heNikud: heNikud) ?? "??"
    }

    private func getParshaString(hdate: HDate, fallbackToHoliday: Bool, heNikud: Bool) -> String? {
        let year = hdate.yy
        var sedra = sedraCache[year]
        if sedra == nil {
            sedra = Sedra(year: year, il: il)
            sedraCache[year] = sedra
        }
        let lang = heNikud && lg == .he ? .heNikud : lg
        let parsha0 = sedra!.lookup(hdate: hdate, lang: lang)
        if parsha0 == nil && !fallbackToHoliday {
            return nil
        }
        return parsha0 == nil ?
            lookupTranslation(str: getHolidayNameForParsha(hdate: hdate), lang: lang) :
            parsha0!
    }

    private let priortyFlags = HolidayFlags([.EREV, .CHAG, .MINOR_HOLIDAY])
    public func pickHolidayToDisplay(date: Date) -> HEvent? {
        let hdate = makeHDate(date: date)
        return self.pickHolidayToDisplay(hdate: hdate)
    }
    public func pickHolidayToDisplay(hdate: HDate) -> HEvent? {
        let holidays = self.getHolidaysOnDate(hdate: hdate)
        if holidays.count == 0 {
            // if there are no holidays today, see if Shabbat is a special Shabbat
            let saturdayAbs = dayOnOrBefore(dayOfWeek: DayOfWeek.SAT, absdate: hdate.abs() + 6)
            let saturday = HDate(absdate: saturdayAbs)
            let satHolidays = self.getHolidaysOnDate(hdate: saturday)
            for h in satHolidays {
                if h.flags.contains(.SPECIAL_SHABBAT) {
                    return h
                }
            }
            return nil // today isn't a holiday and no special shabbat
        } else if holidays.count == 1 {
            return holidays[0]
        } else {
            // multiple holidays today, such as "Erev Pesach" and "Ta'anit Bechorot"
            // so pick the most "important" one to display
            if let h = holidays.first(
                where: { !priortyFlags.intersection($0.flags).isEmpty }) {
                return h
            } else {
                // whatever, just show the first holiday today
                return holidays[0]
            }
        }
    }

    private var doingInit = true
    private init() {
        logger.debug("ModelData init")
        self.il = UserDefaults.standard.bool(forKey: "israel")
        self.lang = UserDefaults.standard.integer(forKey: "lang")
        updateDateItems()
        logger.debug("il=\(self.il), lang=\(self.lang)")
        doingInit = false
    }

    private let dayOfWeek = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let dayOfWeekHe = [
        "",
        "ראשון",
        "שני",
        "שלישי",
        "רביעי",
        "חמישי",
        "שישי",
        "שבת",
    ]
    private let shortMonth = [
        "",
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ]
    private let shortMonthHe = [
        "",
        "ינו",
        "פבר",
        "מרץ",
        "אפר",
        "מאי",
        "יונ",
        "יול",
        "אוג",
        "ספט",
        "אוק",
        "נוב",
        "דצמ",
    ]

    var yearCache: [Int: [HEvent]] = [:]
    var sedraCache: [Int: Sedra] = [:]
    
    private func getHolidaysOnDate(hdate: HDate) -> [HEvent] {
        let year = hdate.yy
        if let events = yearCache[year] {
            return Hebcal.getHolidaysOnDate(events: events, hdate: hdate, il: self.il)
        }
        let events = getAllHolidaysForYear(year: year)
        yearCache[year] = events
        return Hebcal.getHolidaysOnDate(events: events, hdate: hdate, il: self.il)
    }

    public func translateHolidayName(ev: HEvent) -> String {
        if ev.flags.contains(.ROSH_CHODESH) {
            let rch = lookupTranslation(str: "Rosh Chodesh", lang: lg)
            let start = ev.desc.index(ev.desc.startIndex, offsetBy: 13)
            let month0 = String(ev.desc[start..<ev.desc.endIndex])
            let month = lookupTranslation(str: month0, lang: lg)
            return rch + " " + month
        } else if ev.desc == "Rosh Hashana" {
            let holiday = lookupTranslation(str: ev.desc, lang: lg)
            let yearStr = lg == .he ? hebnumToString(number: ev.hdate.yy) : String(ev.hdate.yy)
            return holiday + " " + yearStr
        }
        let holiday = lookupTranslation(str: ev.desc, lang: lg)
        return holiday
    }

    public func pickEmoji(events: [HEvent]) -> String? {
        var isChag = false
        for ev in events {
            if ev.emoji != nil {
                return ev.emoji
            }
            if ev.flags.contains(.CHAG) {
                isChag = true
            }
        }
        if isChag {
            return "✡️"
        }
        return nil
    }

    private func omerDay(hdate: HDate) -> Int {
        switch hdate.mm {
        case .NISAN:
            return hdate.dd >= 16 ? 1 + (hdate.dd - 16) : -1
        case .IYYAR:
            return 15 + hdate.dd
        case .SIVAN:
            return hdate.dd <= 5 ? 44 + hdate.dd : -1
        default:
            return -1
        }
    }

    private func enNumSuffix(_ n: Int) -> String {
        let tens: Int = (n % 100) / 10
        if tens == 1 {
            return "th"
        }
        switch n % 10 {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default:
            return "th"
        }
    }

    public func omerStr(hdate: HDate) -> String? {
        let omer = omerDay(hdate: hdate)
        if omer == -1 {
            return nil
        }
        let o = String(omer)
        return lg == .he ? "עומר יום" + " " + o :
            "Omer: " + o + enNumSuffix(omer) + " day"
    }

    private func parshaStr(hdate: HDate) -> String? {
        let parshaName = self.getParshaString(hdate: hdate, fallbackToHoliday: false, heNikud: false)
        return parshaName
        /*
        let parshaPrefix = parshaName != nil ? lookupTranslation(str: "Parashat", lang: lang) : nil
        let parsha = parshaName != nil ? parshaPrefix! + " " + parshaName! : nil
        return parsha
        */
    }

    public func makeDateItem(date: Date, showYear: Bool, forceParsha: Bool) -> DateItem {
        let dateComponents = gregCalendar.dateComponents([.weekday, .month, .day], from: date)
        let weekday = dateComponents.weekday!
        let hdate = HDate(date: date)
        let showYear0 = (hdate.mm == .TISHREI && hdate.dd == 1) || showYear
        let hdateStr = self.getHebDateString(hdate: hdate, showYear: showYear0)
        let parsha = (forceParsha || weekday == 7) ? parshaStr(hdate: hdate) : nil
        let events = self.getHolidaysOnDate(hdate: hdate)
        var holidays = [String]()
        for ev in events {
            let holiday = translateHolidayName(ev: ev)
            holidays.append(holiday)
        }
        let emoji = pickEmoji(events: events)
        let gregMonth = lg == .he ? shortMonthHe[dateComponents.month!] : shortMonth[dateComponents.month!]
        let dow = lg == .he ? dayOfWeekHe[weekday] : dayOfWeek[weekday]
        return DateItem(
            id: ((hdate.yy * 10000) + (hdate.mm.rawValue * 100) + hdate.dd),
            lang: lg,
            weekday: weekday,
            dow: dow,
            gregDay: dateComponents.day!, gregMonth: gregMonth,
            hdate: hdateStr,
            parsha: parsha,
            holidays: holidays,
            emoji: emoji,
            omer: omerStr(hdate: hdate)
        )
    }

    let twentyFourHours = 24.0 * 60.0 * 60.0

    private func makeDateItems(date: Date) -> [DateItem] {
        var entries = [DateItem]()
        let first = self.makeDateItem(date: date, showYear: true, forceParsha: false)
        entries.append(first)
        // Show everything daily for the next 2 weeks
        var current = date.addingTimeInterval(twentyFourHours)
        let endDate = date.addingTimeInterval(14.0 * twentyFourHours)
        while (current.compare(endDate) == .orderedAscending) {
            let item = self.makeDateItem(date: current, showYear: false, forceParsha: false)
            entries.append(item)
            current = current.addingTimeInterval(twentyFourHours)
        }
        // Then show Shabbat and holidays for the next 4 months
        let today = HDate(date: date)
        let numDays = daysInYear(year: today.yy)
        let startAbs = greg2abs(date: current)
        let endAbs = today.abs() + Int64(numDays)
        for abs in startAbs...endAbs {
            let hdate = HDate(absdate: abs)
            if hdate.dow() == .SAT {
                let item = self.makeDateItem(date: hdate.greg(), showYear: false, forceParsha: true)
                entries.append(item)
            } else {
                let events = self.getHolidaysOnDate(hdate: hdate)
                if events.count > 0 {
                    let item = self.makeDateItem(date: hdate.greg(), showYear: false, forceParsha: false)
                    entries.append(item)
                }
            }
        }
        logger.debug("Made \(entries.count) dateItems")
        return entries
    }

    private var currentDay: Int = -1

    public func updateDateItems() -> Void {
        let now = Date()
        let dateComponents = gregCalendar.dateComponents([.day], from: now)
        let today = dateComponents.day!
        if self.currentDay == today {
            logger.debug("dateItems are already up to date; refresh skipped")
        } else {
            logger.debug("updating dateItems; currentDay changed from \(self.currentDay) to \(today)")
            self.currentDay = today
            self.todayDateItem = makeDateItem(date: now, showYear: true, forceParsha: true)
            self.dateItems = makeDateItems(date: now)
        }
    }

    private var currentTimezone: TimeZone = TimeZone.current

    public func checkTimeZone() -> Void {
        if self.currentTimezone != TimeZone.current {
            logger.debug("reloading complications; timezone changed from \(self.currentTimezone.identifier) to \(TimeZone.current.identifier)")
            self.currentTimezone = TimeZone.current
            self.currentDay = -1
            self.reloadComplications()
        }
    }

    @Published public var todayDateItem: DateItem?
    @Published public var dateItems = [DateItem]()
}
