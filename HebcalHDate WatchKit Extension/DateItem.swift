//
//  DateItem.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 9/5/21.
//

import Foundation

struct DateItem: Hashable, Codable, Identifiable {
    var id = UUID()
    var dow: String
    var gregDay: Int
    var gregMonth: String
    var hdate: String
    var parsha: String
    var holiday: String?
}
