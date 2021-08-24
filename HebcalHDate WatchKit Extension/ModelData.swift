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

    public var currentHebDateStr: String {
        self.getHebDateString(date: Date())
    }

    public func getHebDateString(date: Date) -> String {
        let hdate = HDate(date: date)
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
    
    public var currentParshaStr: String {
        getParshaString(date: Date(), il: il, lang: TranslationLang(rawValue: lang) ?? TranslationLang.en)
    }

    private init() {
        logger.debug("ModelData init")
        self.il = UserDefaults.standard.bool(forKey: "israel")
        self.lang = UserDefaults.standard.integer(forKey: "lang")
    }
}
