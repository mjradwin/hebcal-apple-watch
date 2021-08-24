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

class ModelData: ObservableObject {
    let logger = Logger(subsystem: "com.hebcal.HebcalHDate.watchkitapp.watchkitextension.ModelData", category: "Root View")

    // The data model needs to be accessed both from the app extension
    // and from the complication controller.
    static let shared = ModelData()

    @Published public var il: Bool {
        didSet {
            UserDefaults.standard.set(il, forKey: "israel")
            logger.debug("A value \(self.il) has been assigned to the Israel property.")
        }
    }

    @Published public var lang: Int {
        didSet {
            UserDefaults.standard.set(lang, forKey: "lang")
            logger.debug("A value \(self.lang) has been assigned to the Lang property.")
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
