//
//  MyUtils.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 8/23/21.
//

import Foundation
import Hebcal

let modelData = ModelData.shared

func getHebDateString(forDate date: Date) -> String {
    let hebrewCalendar = Calendar(identifier: Calendar.Identifier.hebrew)
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .none
    dateFormatter.calendar = hebrewCalendar
    return dateFormatter.string(from: date)
}

func getParshaString(date: Date) -> String {
    let hdate = HDate(date: date)
    let sedra = Sedra(year: hdate.yy, il: modelData.il)
    let parsha0 = sedra.lookup(hdate: hdate)
    return parsha0 == nil ? "Holiday" : parsha0!
}
