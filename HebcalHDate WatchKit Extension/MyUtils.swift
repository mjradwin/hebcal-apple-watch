//
//  MyUtils.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 8/23/21.
//

import Foundation
import Hebcal

func getParshaString(date: Date, il: Bool, lang: TranslationLang) -> String {
    let hdate = HDate(date: date)
    let sedra = Sedra(year: hdate.yy, il: il)
    let parsha0 = sedra.lookup(hdate: hdate, lang: lang)
    return parsha0 == nil ? "Holiday" : parsha0!
}
