//
//  DateItem.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 9/5/21.
//

import Foundation
import Hebcal

struct DateItem: Hashable, Codable, Identifiable {
    var id: Int
    var lang: TranslationLang
    var weekday: Int
    var dow: String
    var gregDay: Int
    var gregMonth: String
    var hdate: String
    var parsha: String?
    var holidays: [String]
    var omer: String?
}
