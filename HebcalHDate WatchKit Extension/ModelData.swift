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

    public func getHolidayString(date: Date) -> String {
        let hdate = makeHDate(date: date)
        let holidays = getHolidaysOnDate(hdate: hdate, il: il)
        if holidays.count == 0 {
            return ""
        }
        var result = [String]()
        let lang = TranslationLang(rawValue: lang) ?? TranslationLang.en
        for h in holidays {
            let desc = lookupTranslation(str: h.desc, lang: lang)
            result.append(desc)
        }
        return result[0]
    }

    public var currenHolidayStr: String {
        self.getHolidayString(date: Date())
    }

    private init() {
        logger.debug("ModelData init")
        self.il = UserDefaults.standard.bool(forKey: "israel")
        self.lang = UserDefaults.standard.integer(forKey: "lang")
    }
}
