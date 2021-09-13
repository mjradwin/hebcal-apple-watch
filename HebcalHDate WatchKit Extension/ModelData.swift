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

class ModelData: ObservableObject {
    let logger = Logger(
        subsystem: "com.hebcal.HebcalHDate.watchkitapp.watchkitextension.ModelData",
        category: "Model")

    // The data model needs to be accessed both from the app extension
    // and from the complication controller.
    static let shared = ModelData()

    @Published public var il: Bool {
        didSet {
            logger.debug("il=\(self.il)")
            UserDefaults.standard.set(il, forKey: "israel")
            sedraCache = [:]
            updateDateItems()
            // Update any complications on active watch faces.
            let server = CLKComplicationServer.sharedInstance()
            for complication in server.activeComplications ?? [] {
                server.reloadTimeline(for: complication)
            }
            logger.debug("il Finished reloadTimeline")
        }
    }

    @Published public var lang: Int {
        didSet {
            logger.debug("lang=\(self.lang)")
            UserDefaults.standard.set(lang, forKey: "lang")
            updateDateItems()
            // Update any complications on active watch faces.
            let server = CLKComplicationServer.sharedInstance()
            for complication in server.activeComplications ?? [] {
                server.reloadTimeline(for: complication)
            }
            logger.debug("lang Finished reloadTimeline")
        }
    }

    private let gregCalendar = Calendar(identifier: .gregorian)
    public func makeHDate(date: Date) -> HDate {
        var hdate = HDate(date: date)
        let hour = gregCalendar.dateComponents([.hour], from: date).hour!
        if (hour > 19) {
            hdate = HDate(absdate: hdate.abs() + 1)
        }
        return hdate
        // return HDate(yy: 5795, mm: .TISHREI, dd: 8)
    }

    public func getHebDateString(date: Date, showYear: Bool) -> String {
        let hdate = makeHDate(date: date)
        return self.getHebDateString(hdate: hdate, showYear: showYear)
    }

    public func getHebDateString(hdate: HDate, showYear: Bool) -> String {
        let monthName = hdate.monthName()
        let lang = TranslationLang(rawValue: lang) ?? TranslationLang.en
        if lang == .he {
            var str = hebnumToString(number: hdate.dd) + " " +
                lookupTranslation(str: monthName, lang: lang)
            if showYear {
                str += " " + hebnumToString(number: hdate.yy)
            }
            return str
        } else {
            var str = String(hdate.dd) + " " + monthName
            if showYear {
                str += " " + String(hdate.yy)
            }
            return str
        }
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

    public func getParshaString(date: Date) -> String {
        let hdate = makeHDate(date: date)
        return self.getParshaString(hdate: hdate, fallbackToHoliday: true) ?? "??"
    }

    private func getParshaString(hdate: HDate, fallbackToHoliday: Bool) -> String? {
        let year = hdate.yy
        var sedra = sedraCache[year]
        if sedra == nil {
            sedra = Sedra(year: year, il: il)
            sedraCache[year] = sedra
        }
        let lang = TranslationLang(rawValue: lang) ?? TranslationLang.en
        let parsha0 = sedra!.lookup(hdate: hdate, lang: lang)
        if parsha0 == nil && !fallbackToHoliday {
            return nil
        }
        return parsha0 == nil ?
            lookupTranslation(str: getHolidayNameForParsha(hdate: hdate), lang: lang) :
            parsha0!
    }

    private let priortyFlags = HolidayFlags([.EREV, .CHAG, .MINOR_HOLIDAY])
    private func pickHolidayToDisplay(date: Date) -> HEvent? {
        let hdate = makeHDate(date: date)
        return self.pickHolidayToDisplay(hdate: hdate)
    }
    private func pickHolidayToDisplay(hdate: HDate) -> HEvent? {
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
    public func getHolidayString(date: Date) -> String? {
        if let ev = pickHolidayToDisplay(date: date) {
            return translateHolidayName(ev: ev)
        }
        return nil // today isn't a holiday and no special shabbat
    }

    private init() {
        logger.debug("ModelData init")
        self.il = UserDefaults.standard.bool(forKey: "israel")
        self.lang = UserDefaults.standard.integer(forKey: "lang")
        self.dateItems = self.makeDateItems(date: Date())
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

    private func translateHolidayName(ev: HEvent) -> String {
        let lg = TranslationLang(rawValue: lang) ?? TranslationLang.en
        if ev.flags.contains(.ROSH_CHODESH) {
            let rch = lookupTranslation(str: "Rosh Chodesh", lang: lg)
            let start = ev.desc.index(ev.desc.startIndex, offsetBy: 13)
            let month0 = String(ev.desc[start..<ev.desc.endIndex])
            let month = lookupTranslation(str: month0, lang: lg)
            return rch + " " + month
        }
        let holiday = lookupTranslation(str: ev.desc, lang: lg)
        return holiday
    }

    private func pickEmoji(events: [HEvent]) -> String? {
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

    private func makeDateItem(date: Date) -> DateItem {
        let dateComponents = gregCalendar.dateComponents([.weekday, .month, .day], from: date)
        let weekday = dateComponents.weekday!
        let hdate = HDate(date: date)
        var hdateStr = self.getHebDateString(hdate: hdate, showYear: false)
        let parshaName = (weekday == 7) ? self.getParshaString(hdate: hdate, fallbackToHoliday: false) : nil
        let lang = TranslationLang(rawValue: lang) ?? TranslationLang.en
        let parshaPrefix = parshaName != nil ? lookupTranslation(str: "Parashat", lang: lang) : nil
        let parsha = parshaName != nil ? parshaPrefix! + " " + parshaName! : nil
        let events = self.getHolidaysOnDate(hdate: hdate)
        var holidays = [String]()
        for ev in events {
            let holiday = translateHolidayName(ev: ev)
            holidays.append(holiday)
        }
        let emoji = pickEmoji(events: events)
        if emoji != nil {
            hdateStr += "  " + emoji!
        }
        let gregMonth = lang == .he ? shortMonthHe[dateComponents.month!] : shortMonth[dateComponents.month!]
        let dow = lang == .he ? dayOfWeekHe[weekday] : dayOfWeek[weekday]
        return DateItem(
            id: ((hdate.yy * 10000) + (hdate.mm.rawValue * 100) + hdate.dd),
            weekday: weekday,
            dow: dow,
            gregDay: dateComponents.day!, gregMonth: gregMonth,
            hdate: hdateStr,
            parsha: parsha,
            holidays: holidays)
    }

    let twentyFourHours = 24.0 * 60.0 * 60.0

    private func makeDateItems(date: Date) -> [DateItem] {
        var entries = [DateItem]()
        // Calculate the start and end dates.
        var current = date
        let endDate = date.addingTimeInterval(60.0 * twentyFourHours)
        while (current.compare(endDate) == .orderedAscending) {
            let item = self.makeDateItem(date: current)
            entries.append(item)
            current = current.addingTimeInterval(twentyFourHours)
        }
        return entries
    }

    public func updateDateItems() -> Void {
        logger.debug("updating dateItems")
        dateItems = makeDateItems(date: Date())
    }

    @Published var dateItems = [DateItem]()
}
