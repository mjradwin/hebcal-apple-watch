//
//  ComplicationController.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 8/17/21.
//

import ClockKit
import os
import Hebcal
import SwiftUI

let monthAbbrev = [
    "Adar": nil,
    "Adar I": "Adar1",
    "Adar II": "Adar2",
    "Av": nil,
    "Cheshvan": "Chesh",
    "Elul": nil,
    "Iyyar": "Iyar",
    "Kislev": "Kis",
    "Nisan": nil,
    "Sh'vat": "Shvat",
    "Sivan": nil,
    "Tamuz": nil,
    "Tevet": nil,
    "Tishrei": "Tish",
]

let parshaHyphenate = [
    "Achrei Mot": nil,
    "Balak": nil,
    "Bamidbar": ["Bamid", "bar"],
    "Bechukotai": ["Bechu", "kotai"],
    "Beha'alotcha": ["Behaa", "lotcha"],
    "Behar": nil,
    "Bereshit": ["Bere-", "sheet"],
    "Beshalach": ["Besha", "lach"],
    "Bo": nil,
    "Chayei Sara": nil,
    "Chukat": nil,
    "Devarim": ["Deva-", "rim"],
    "Eikev": nil,
    "Emor": nil,
    "Ha'Azinu": ["Ha-", "Azinu"],
    "Kedoshim": ["Kedo-", "shim"],
    "Ki Tavo": nil,
    "Ki Teitzei": nil,
    "Ki Tisa": nil,
    "Korach": nil,
    "Lech-Lecha": nil,
    "Masei": nil,
    "Matot": nil,
    "Metzora": ["Metz-", "ora"],
    "Miketz": ["Mi-", "ketz"],
    "Mishpatim": ["Mish-", "patim"],
    "Nasso": nil,
    "Nitzavim": ["Nitz-", "avim"],
    "Noach": nil,
    "Pekudei": ["Peku-", "dei"],
    "Pinchas": ["Pin-", "chas"],
    "Re'eh": nil,
    "Sh'lach": ["Sh'", "lach"],
    "Shemot": nil,
    "Shmini": nil,
    "Shoftim": ["Shof-", "tim"],
    "Tazria": nil,
    "Terumah": ["Teru-", "mah"],
    "Tetzaveh": ["Tet-", "zaveh"],
    "Toldot": ["Tol-", "dot"],
    "Tzav": nil,
    "Vaera": nil,
    "Vaetchanan": ["Vaet-", "chanan"],
    "Vayakhel": ["Vaya-", "khel"],
    "Vayechi": nil,
    "Vayeilech": ["Vayei", "lech"],
    "Vayera": nil,
    "Vayeshev": ["Vaye-", "shev"],
    "Vayetzei": ["Vaye-", "tzei"],
    "Vayigash": ["Vayi-", "gash"],
    "Vayikra": ["Vayi-", "kra"],
    "Vayishlach": ["Vayish", "lach"],
    "Yitro": nil,
    // ashk
    "Bechukosai": ["Bechu", "kosai"],
    "Beha'aloscha": ["Behaa", "loscha"],
    "Bereshis": ["Bere-", "shis"],
    "Toldos": ["Tol-", "dos"],
    "Vaeschanan": ["Vaes-", "chanan"],
]

struct OneLineTextView: View {
    var text: String
    var body: some View {
        Text(text)
    }
}

class ComplicationController: NSObject, CLKComplicationDataSource {
    lazy var settings = ModelData.shared
    let logger = Logger(subsystem: "com.hebcal.HebcalHDate.watchkitapp.watchkitextension.ComplicationController", category: "Complication")

    // MARK: - Complication Configuration

    private let complicationHebcalIdentifier = "complicationHebcal"
    private let complicationHdateIdentifier = "complicationHdate"
    private let complicationParshaIdentifier = "complicationParsha"

    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(
                identifier: complicationHebcalIdentifier,
                displayName: "Hebcal",
                supportedFamilies: [.utilitarianLarge, .modularLarge, .graphicRectangular]),
            CLKComplicationDescriptor(
                identifier: complicationHdateIdentifier,
                displayName: "Hebrew Date",
                supportedFamilies: [
                    .modularSmall,
                    .circularSmall,
                    .utilitarianSmall,
                    .utilitarianSmallFlat,
                    .graphicCorner,
                    .graphicCircular
                ]),
            CLKComplicationDescriptor(
                identifier: complicationParshaIdentifier,
                displayName: "Torah Portion",
                supportedFamilies: [
                    .modularSmall,
                    .circularSmall,
                    .utilitarianSmall,
                    .utilitarianSmallFlat,
                    .graphicCircular
                ])
            // Multiple complication support can be added here with more descriptors
        ]
        
        // Call the handler with the currently supported complication descriptors
        handler(descriptors)
    }
    
    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
        // Do any necessary work to support these newly shared complication descriptors
    }

    func makeTimelineDates(date: Date) -> [Date] {
        let dateComponents = gregCalendar.dateComponents([.hour], from: date)
        if dateComponents.hour! < 20 {
            let sevenFiftyNine = gregCalendar.date(bySettingHour: 19, minute: 59, second: 59, of: date)!
            let eightPm = gregCalendar.date(bySettingHour: 20, minute: 0, second: 0, of: date)!
            let midnight = eightPm.addingTimeInterval(4.0 * 60.0 * 60.0)
            let endDate = gregCalendar.date(bySettingHour: 19, minute: 59, second: 59, of: midnight)!
            return [date, sevenFiftyNine, eightPm, midnight, endDate]
        } else {
            let elevenFiftyNine = gregCalendar.date(bySettingHour: 23, minute: 59, second: 59, of: date)!
            let midnight = elevenFiftyNine.addingTimeInterval(1.0)
            let endDate = gregCalendar.date(bySettingHour: 19, minute: 59, second: 59, of: midnight)!
            return [date, elevenFiftyNine, midnight, endDate]
        }
    }

    // MARK: - Timeline Configuration

    // Define how far into the future the app can provide data.
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        let dates = makeTimelineDates(date: Date())
        let endDate = dates[dates.count - 1]
        logger.debug("getTimelineEndDate \(complication.identifier) \(endDate)")
        handler(endDate)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // Call the handler with your desired behavior when the device is locked
        handler(.showOnLockScreen)
    }

    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Call the handler with the current timeline entry
        handler(createTimelineEntry(forComplication: complication, date: Date()))
    }

    // Return future timeline entries.
    func getTimelineEntries(for complication: CLKComplication,
                            after date: Date,
                            limit: Int,
                            withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        logger.debug("getTimelineEntries \(complication.identifier) \(date) \(limit)")
        let dates = makeTimelineDates(date: date)
        // Create an array to hold the timeline entries.
        var entries = [CLKComplicationTimelineEntry]()
        for dt in dates {
            entries.append(createTimelineEntry(forComplication: complication, date: dt))
        }
        handler(entries)
    }

    private let gregCalendar = Calendar(identifier: .gregorian)

    // MARK: - Sample Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        var dateComponents = DateComponents()
        dateComponents.year = 2020
        dateComponents.month = 1
        dateComponents.day = 1
        let date = gregCalendar.date(from: dateComponents)!

        var template: CLKComplicationTemplate?
        if complication.identifier == complicationHebcalIdentifier {
            template = createHebcalTemplate(forComplication: complication, date: date)
        } else {
            switch complication.family {
            case .modularSmall, .utilitarianSmall, .utilitarianSmallFlat, .circularSmall, .graphicCircular:
                template = complication.identifier == complicationHdateIdentifier ?
                    createHDateTemplate(forComplication: complication, date: date) :
                    createParshaTemplate(forComplication: complication, date: date)
            case .graphicCorner:
                template = complication.identifier == complicationHdateIdentifier ?
                    createHDateTemplate(forComplication: complication, date: date) :
                    nil
            default:
                template = nil
            }
        }
        handler(template)
    }

    // Return a timeline entry for the specified complication and date.
    private func createTimelineEntry(forComplication complication: CLKComplication, date: Date) -> CLKComplicationTimelineEntry {

        if complication.identifier == complicationHebcalIdentifier {
            let template = createHebcalTemplate(forComplication: complication, date: date)
            if template == nil {
                fatalError("*** Unsupported Complication Family ***")
            }
            return CLKComplicationTimelineEntry(date: date, complicationTemplate: template!)
        }

        // Get the correct template based on the complication.
        let template = complication.identifier == complicationHdateIdentifier ?
                createHDateTemplate(forComplication: complication, date: date) :
                createParshaTemplate(forComplication: complication, date: date)
        if template == nil {
            fatalError("*** Unsupported Complication Family ***")
        }
        // Use the template and date to create a timeline entry.
        return CLKComplicationTimelineEntry(date: date, complicationTemplate: template!)
    }

    // Select the correct template based on the complication's family.
    private func createHebcalTemplate(forComplication complication: CLKComplication, date: Date) -> CLKComplicationTemplate? {
        switch complication.family {
        case .modularLarge:
            return createModularLargeTemplate(forDate: date)
        case .graphicRectangular:
            return createGraphicRectangularTemplate(forDate: date)
        case .utilitarianLarge:
            return createUtilitarianLargeTemplate(forDate: date)
        default:
            return nil
        }
    }

    private func createParshaTemplate(forComplication complication: CLKComplication, date: Date) -> CLKComplicationTemplate? {
        switch complication.family {
        case .modularSmall:
            return createParshaModularSmallTemplate(forDate: date)
        case .utilitarianSmall, .utilitarianSmallFlat:
            return createParshaUtilitarianSmallFlatTemplate(forDate: date)
        case .circularSmall:
            return createParshaCircularSmallTemplate(forDate: date)
        case .graphicCorner:
            logger.error("Unsupported Parsha Complication Family")
            return nil
        case .graphicCircular:
            return createParshaGraphicCircleTemplate(forDate: date)
        case .modularLarge, .utilitarianLarge, .extraLarge, .graphicRectangular, .graphicBezel, .graphicExtraLarge:
            logger.error("Unsupported Parsha Complication Family")
            return nil
        @unknown default:
            fatalError("*** Unknown Complication Family ***")
        }
    }

    private func createHDateTemplate(forComplication complication: CLKComplication, date: Date) -> CLKComplicationTemplate? {
        switch complication.family {
        case .modularSmall:
            return createHDateModularSmallTemplate(forDate: date)
        case .utilitarianSmall, .utilitarianSmallFlat:
            return createHDateUtilitarianSmallFlatTemplate(forDate: date)
        case .circularSmall:
            return createHDateCircularSmallTemplate(forDate: date)
        case .graphicCorner:
            return createHDateGraphicCornerTemplate(forDate: date)
        case .graphicCircular:
            return createHDateGraphicCircleTemplate(forDate: date)
        case .modularLarge, .utilitarianLarge, .extraLarge, .graphicRectangular, .graphicBezel, .graphicExtraLarge:
            logger.error("Unsupported HDate Complication Family")
            return nil
        @unknown default:
            fatalError("*** Unknown Complication Family ***")
        }
    }

    private var tintColor: UIColor = UIColor(
        red: 1.0, green: 0.75, blue: 0.0, alpha: 1.0)
    private func makeHDateSimpleTextProviders(date: Date) -> [CLKSimpleTextProvider] {
        let hebDateStr = settings.getHebDateString(date: date, showYear: false)
        let parts = hebDateStr.split(separator: " ")
        let dayNumber = String(parts[0])
        let monthName = String(parts[1])
        let dayNumberProvider = CLKSimpleTextProvider(text: dayNumber)
        dayNumberProvider.tintColor = .white
        let monthNameProvider = CLKSimpleTextProvider(text: monthName, shortText: monthAbbrev[monthName] ?? nil)
        monthNameProvider.tintColor = tintColor
        return [dayNumberProvider, monthNameProvider]
    }

    // Return a modular small template.
    private func createHDateModularSmallTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let hdateProviders = makeHDateSimpleTextProviders(date: date)
        // Create the template using the providers.
        return CLKComplicationTemplateModularSmallStackText(
            line1TextProvider: hdateProviders[0],
            line2TextProvider: hdateProviders[1])
    }
    
    // Return a utilitarian small flat template.
    private func createHDateUtilitarianSmallFlatTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let hebDateStr = settings.getHebDateString(date: date, showYear: false)
        let textProvider = CLKSimpleTextProvider(text: hebDateStr)

        // Create the template using the providers.
        return CLKComplicationTemplateUtilitarianSmallFlat(textProvider: textProvider)
    }

    private let largeFlatFormatRTL = "\u{202E}%@ · %@"
    private let largeFlatFormatLTR = "%@ · %@"

    // Return a utilitarian large template.
    private func createUtilitarianLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let hebDateStr = settings.getHebDateString(date: date, showYear: false)
        let parshaName = settings.getParshaString(date: date, heNikud: false)
        let lang = TranslationLang(rawValue: settings.lang)!
        let format = lang == .he ? largeFlatFormatRTL : largeFlatFormatLTR
        let combinedProvider = CLKTextProvider(format: format, hebDateStr, parshaName)
        // Create the template using the providers.
        return CLKComplicationTemplateUtilitarianLargeFlat(textProvider: combinedProvider)
    }

    // Return a circular small template.
    private func createHDateCircularSmallTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let hdateProviders = makeHDateSimpleTextProviders(date: date)
        // Create the template using the providers.
        return CLKComplicationTemplateCircularSmallStackText(
            line1TextProvider: hdateProviders[0],
            line2TextProvider: hdateProviders[1])
    }
        
    // Return a graphic template that fills the corner of the watch face.
    private func createHDateGraphicCornerTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let hdateProviders = makeHDateSimpleTextProviders(date: date)
        // Create the template using the providers.
        return CLKComplicationTemplateGraphicCornerStackText(innerTextProvider: hdateProviders[1],
                                                             outerTextProvider: hdateProviders[0])
    }

    // Return a graphic circle template.
    private func createHDateGraphicCircleTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let hdateProviders = makeHDateSimpleTextProviders(date: date)
        // Create the template using the providers.
        let lang = TranslationLang(rawValue: settings.lang)!
        if lang == .he {
            return CLKComplicationTemplateGraphicCircularOpenGaugeSimpleText(
                gaugeProvider: CLKSimpleGaugeProvider(
                    style: .fill,
                    gaugeColor: tintColor,
                    fillFraction: CLKSimpleGaugeProviderFillFractionEmpty),
                bottomTextProvider: hdateProviders[1],
                centerTextProvider: hdateProviders[0])
        }
        return CLKComplicationTemplateGraphicCircularStackText(
            line1TextProvider: hdateProviders[0],
            line2TextProvider: hdateProviders[1])
    }

    // Return a modular small template.
    private func createParshaModularSmallTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let simpleTextProviders = makeParshaSimpleTextProviders(date: date);
        if simpleTextProviders.count == 1 {
            return CLKComplicationTemplateModularSmallSimpleText(
                textProvider: simpleTextProviders[0])
        }
        return CLKComplicationTemplateModularSmallStackText(
            line1TextProvider: simpleTextProviders[0],
            line2TextProvider: simpleTextProviders[1])
    }

    // Return a utilitarian small flat template.
    private func createParshaUtilitarianSmallFlatTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let parsha = settings.getParshaString(date: date, heNikud: false)
        // Create the data providers.
        let parshaNameProvider = CLKSimpleTextProvider(text: parsha)
        // Create the template using the providers.
        return CLKComplicationTemplateUtilitarianSmallFlat(textProvider: parshaNameProvider)
    }

    private let space: Character = " "
    private let dash: Character = "-"
    private let maqaf: Character = "־"

    private func makeParshaSimpleTextProviders(date: Date) -> [CLKSimpleTextProvider] {
        let parsha = settings.getParshaString(date: date, heNikud: true)
        for delim in [dash, maqaf, space] {
            if (parsha.firstIndex(of: delim) != nil) {
                let parts = self.splitFirstChar(str: parsha, char: delim)
                return [
                    CLKSimpleTextProvider(text: parts[0]),
                    CLKSimpleTextProvider(text: parts[1])
                ]
            }
        }
        if let hyphenated = parshaHyphenate[parsha] {
            if hyphenated == nil {
                return [
                    CLKSimpleTextProvider(text: parsha)
                ]
            }
            return [
                CLKSimpleTextProvider(text: hyphenated![0]),
                CLKSimpleTextProvider(text: hyphenated![1])
            ]
        }
        return [
            CLKSimpleTextProvider(text: parsha)
        ]
    }

    // Return a circular small template.
    private func createParshaCircularSmallTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let simpleTextProviders = makeParshaSimpleTextProviders(date: date);
        if simpleTextProviders.count == 1 {
            return CLKComplicationTemplateCircularSmallSimpleText(textProvider: simpleTextProviders[0])
        }
        return CLKComplicationTemplateCircularSmallStackText(
            line1TextProvider: simpleTextProviders[0],
            line2TextProvider: simpleTextProviders[1])
    }

    private func splitFirstChar(str: String, char: Character) -> [String] {
        if let idx = str.firstIndex(of: char) {
            let firstWord = String(str[..<idx])
            let afterIdx = str.index(idx, offsetBy: 1)
            let remainder = String(str[afterIdx...])
            return [firstWord, remainder]
        } else {
            return [str]
        }
    }

    // Return a graphic circle template.
    private func createParshaGraphicCircleTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let simpleTextProviders = makeParshaSimpleTextProviders(date: date);
        if simpleTextProviders.count == 1 {
            return CLKComplicationTemplateGraphicCircularView(
                OneLineTextView(text: simpleTextProviders[0].text))
        }
        return CLKComplicationTemplateGraphicCircularStackText(
            line1TextProvider: simpleTextProviders[0],
            line2TextProvider: simpleTextProviders[1])
    }

    private func create3lineTextProviders(date: Date) -> [CLKSimpleTextProvider] {
        let hebDateStr = settings.getHebDateString(date: date, showYear: true)
        let headerTextProvider = CLKSimpleTextProvider(text: hebDateStr)
        headerTextProvider.tintColor = tintColor

        let lang = TranslationLang(rawValue: settings.lang)!
        let parshaName = settings.getParshaString(date: date, heNikud: false)
        let parshaPrefix = lookupTranslation(str: "Parashat", lang: lang)
        let parsha = parshaPrefix + " " + parshaName
        let parshaProvider = CLKSimpleTextProvider(text: parsha)

        let holidayToday = settings.getHolidayString(date: date)
        let holidayProvider = CLKSimpleTextProvider(text: holidayToday ?? "")
        return [
            headerTextProvider,
            holidayToday == nil ? parshaProvider : holidayProvider,
            holidayToday != nil ? parshaProvider : holidayProvider,
        ]
    }

    // Return a modular large template.
    private func createModularLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let textProviders = create3lineTextProviders(date: date)

        // Create the template using the providers.
        return CLKComplicationTemplateModularLargeStandardBody(
            headerTextProvider: textProviders[0],
            body1TextProvider: textProviders[1],
            body2TextProvider: textProviders[2])
    }

    // Return a large rectangular graphic template.
    private func createGraphicRectangularTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let textProviders = create3lineTextProviders(date: date)

        // Create the template using the providers.
        return CLKComplicationTemplateGraphicRectangularStandardBody(
            headerTextProvider: textProviders[0],
            body1TextProvider: textProviders[1],
            body2TextProvider: textProviders[2])
    }
}
