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
    let logger = Logger(subsystem: "com.hebcal.HebcalHDate.watchkitapp.watchkitextension.ModelData", category: "Root View")

    // The data model needs to be accessed both from the app extension
    // and from the complication controller.
    static let shared = ModelData()

    @Published public var il: Bool {
        didSet {
            logger.debug("il=\(self.il)")
            UserDefaults.standard.set(il, forKey: "israel")
            // Update any complications on active watch faces.
            let server = CLKComplicationServer.sharedInstance()
            logger.debug("il ComplicationServer.sharedInstance")
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
            // Update any complications on active watch faces.
            let server = CLKComplicationServer.sharedInstance()
            logger.debug("lang ComplicationServer.sharedInstance")
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

    public var currentHebDateStr: String {
        self.getHebDateString(date: Date())
    }

    public func getHebDateString(date: Date) -> String {
        let hdate = makeHDate(date: date)
        let monthName = hdate.monthName()
        let lang = TranslationLang(rawValue: lang) ?? TranslationLang.en
        if lang == .he {
            return hebnumToString(number: hdate.dd) + " " +
                lookupTranslation(str: monthName, lang: lang) + " " +
                hebnumToString(number: hdate.yy)
        } else {
            return String(hdate.dd) + " " + monthName + " " + String(hdate.yy)
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
        let sedra = Sedra(year: hdate.yy, il: il)
        let lang = TranslationLang(rawValue: lang) ?? TranslationLang.en
        let parsha0 = sedra.lookup(hdate: hdate, lang: lang)
        return parsha0 == nil ?
            lookupTranslation(str: getHolidayNameForParsha(hdate: hdate), lang: lang) :
            parsha0!
    }

    public var currentParshaStr: String {
        self.getParshaString(date: Date())
    }

    private let priortyFlags = HolidayFlags([.EREV, .CHAG, .MINOR_HOLIDAY])
    private func pickHolidayToDisplay(date: Date) -> HEvent? {
        let hdate = makeHDate(date: date)
        let holidays = getHolidaysOnDate(hdate: hdate, il: il)
        if holidays.count == 0 {
            // if there are no holidays today, see if Shabbat is a special Shabbat
            let saturdayAbs = dayOnOrBefore(dayOfWeek: DayOfWeek.SAT, absdate: hdate.abs() + 6)
            let saturday = HDate(absdate: saturdayAbs)
            let satHolidays = getHolidaysOnDate(hdate: saturday, il: il)
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
        let lang = TranslationLang(rawValue: lang) ?? TranslationLang.en
        if let ev = pickHolidayToDisplay(date: date) {
            return lookupTranslation(str: ev.desc, lang: lang)
        }
        return nil // today isn't a holiday and no special shabbat
    }

    public var currenHolidayStr: String? {
        self.getHolidayString(date: Date())
    }

    private init() {
        logger.debug("ModelData init")
        self.il = UserDefaults.standard.bool(forKey: "israel")
        self.lang = UserDefaults.standard.integer(forKey: "lang")
    }

    private let shortMonth = [
        "",
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ]
    public func makeDateItem(date: Date) -> DateItem {
        let ymd = gregCalendar.dateComponents([.year, .month, .day], from: date)
        let hdate = self.getHebDateString(date: date)
        let parsha = self.getParshaString(date: date)
        let holiday = self.getHolidayString(date: date)
        return DateItem(
            gregDay: ymd.day!, gregMonth: shortMonth[ymd.month!],
            hdate: hdate, parsha: parsha, holiday: holiday)
    }

    let tenDays = 10.0 * 24.0 * 60.0 * 60.0
    let twentyFourHours = 24.0 * 60.0 * 60.0

    public func makeDateItems(date: Date) -> [DateItem] {
        var entries = [DateItem]()
        // Calculate the start and end dates.
        var current = date
        let endDate = date.addingTimeInterval(tenDays)
        while (current.compare(endDate) == .orderedAscending) {
            let item = self.makeDateItem(date: current)
            entries.append(item)
            current = current.addingTimeInterval(twentyFourHours)
        }
        return entries
    }
}
