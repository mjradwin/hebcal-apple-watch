//
//  ComplicationController.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 8/17/21.
//

import ClockKit
import os
import Hebcal

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

class ComplicationController: NSObject, CLKComplicationDataSource {
    lazy var settings = ModelData.shared
    let logger = Logger(subsystem: "com.hebcal.HebcalHDate.watchkitapp.watchkitextension.ComplicationController", category: "Root View")

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

    let thirtyMinutes = 30.0 * 60.0
    let sixtyMinutes = 60.0 * 60.0
    let fortyEightFourHours = 48.0 * 60.0 * 60.0

    // MARK: - Timeline Configuration

    // Define how far into the future the app can provide data.
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Indicate that the app can provide timeline entries for the next 30 days
        let endDate = Date().addingTimeInterval(fortyEightFourHours)
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

        // Create an array to hold the timeline entries.
        var entries = [CLKComplicationTimelineEntry]()
        
        // Calculate the start and end dates.
        var current = date.addingTimeInterval(thirtyMinutes)
        let endDate = date.addingTimeInterval(fortyEightFourHours)
    
        // Create a timeline entry for every hour from the starting time.
        // Stop once you reach the limit or the end date.
        while (current.compare(endDate) == .orderedAscending) && (entries.count < limit) {
            entries.append(createTimelineEntry(forComplication: complication, date: current))
            current = current.addingTimeInterval(sixtyMinutes)
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
            case .modularSmall, .utilitarianSmall, .utilitarianSmallFlat, .circularSmall, .graphicCorner, .graphicCircular:
                template = complication.identifier == complicationHdateIdentifier ?
                    createHDateTemplate(forComplication: complication, date: date) :
                    createParshaTemplate(forComplication: complication, date: date)
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

    private func makeHDateSimpleTextProviders(date: Date) -> [CLKSimpleTextProvider] {
        let hebDateStr = settings.getHebDateString(date: date)
        let parts = hebDateStr.split(separator: " ")
        let dayNumber = String(parts[0])
        let monthName = String(parts[1])
        let dayNumberProvider = CLKSimpleTextProvider(text: dayNumber)
        dayNumberProvider.tintColor = .orange
        let monthNameProvider = CLKSimpleTextProvider(text: monthName, shortText: monthAbbrev[monthName] ?? nil)
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
        let hdateProviders = makeHDateSimpleTextProviders(date: date)
        let combinedProvider = CLKTextProvider(format: "%@ %@", hdateProviders[0], hdateProviders[1])

        // Create the template using the providers.
        return CLKComplicationTemplateUtilitarianSmallFlat(textProvider: combinedProvider)
    }

    // Return a utilitarian large template.
    private func createUtilitarianLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let hdateProviders = makeHDateSimpleTextProviders(date: date)
        let parshaName = settings.getParshaString(date: date)
        let combinedProvider = CLKTextProvider(format: "%@ %@ · %@", hdateProviders[0], hdateProviders[1], parshaName)
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
        return CLKComplicationTemplateGraphicCircularStackText(
            line1TextProvider: hdateProviders[0],
            line2TextProvider: hdateProviders[1])
    }

    // Return a modular small template.
    private func createParshaModularSmallTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let simpleTextProviders = makeParshaSimpleTextProviders(date: date);
        return CLKComplicationTemplateModularSmallStackText(
            line1TextProvider: simpleTextProviders[0],
            line2TextProvider: simpleTextProviders[1])
    }

    // Return a utilitarian small flat template.
    private func createParshaUtilitarianSmallFlatTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let parsha = settings.getParshaString(date: date)
        // Create the data providers.
        let parshaNameProvider = CLKSimpleTextProvider(text: parsha)
        // Create the template using the providers.
        return CLKComplicationTemplateUtilitarianSmallFlat(textProvider: parshaNameProvider)
    }

    private let space: Character = " "
    private let dash: Character = "-"
    private let maqaf: Character = "־"

    private func makeParshaSimpleTextProviders(date: Date) -> [CLKSimpleTextProvider] {
        let parsha = settings.getParshaString(date: date)
        for delim in [dash, space, maqaf] {
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
                    CLKSimpleTextProvider(text: parsha),
                    CLKSimpleTextProvider(text: "")
                ]
            }
            return [
                CLKSimpleTextProvider(text: hyphenated![0]),
                CLKSimpleTextProvider(text: hyphenated![1])
            ]
        }
        return [
            CLKSimpleTextProvider(text: parsha),
            CLKSimpleTextProvider(text: "")
        ]
    }

    // Return a circular small template.
    private func createParshaCircularSmallTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let simpleTextProviders = makeParshaSimpleTextProviders(date: date);
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
        return CLKComplicationTemplateGraphicCircularStackText(
            line1TextProvider: simpleTextProviders[0],
            line2TextProvider: simpleTextProviders[1])
    }

    // Return a modular large template.
    private func createModularLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let hebDateStr = settings.getHebDateString(date: date)
        let headerTextProvider = CLKSimpleTextProvider(text: hebDateStr)
        headerTextProvider.tintColor = .orange

        let lang = TranslationLang(rawValue: settings.lang)!
        let parshaName = settings.getParshaString(date: date)
        let parshaPrefix = lookupTranslation(str: "Parashat", lang: lang)
        let parsha = parshaPrefix + " " + parshaName
        let body1TextProvider = CLKSimpleTextProvider(text: parsha)

        let holidayToday = settings.getHolidayString(date: date)
        let body2TextProvider = CLKSimpleTextProvider(text: holidayToday)

        // Create the template using the providers.
        return CLKComplicationTemplateModularLargeStandardBody(
            headerTextProvider: headerTextProvider,
            body1TextProvider: body1TextProvider,
            body2TextProvider: body2TextProvider)
    }
    
    // Return a large rectangular graphic template.
    private func createGraphicRectangularTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let hebDateStr = settings.getHebDateString(date: date)
        let headerTextProvider = CLKSimpleTextProvider(text: hebDateStr)
        headerTextProvider.tintColor = .orange

        let lang = TranslationLang(rawValue: settings.lang)!
        let parshaName = settings.getParshaString(date: date)
        let parshaPrefix = lookupTranslation(str: "Parashat", lang: lang)
        let parsha = parshaPrefix + " " + parshaName
        let body1TextProvider = CLKSimpleTextProvider(text: parsha)

        let holidayToday = settings.getHolidayString(date: date)
        let body2TextProvider = CLKSimpleTextProvider(text: holidayToday)

        // Create the template using the providers.
        return CLKComplicationTemplateGraphicRectangularStandardBody(
            headerTextProvider: headerTextProvider,
            body1TextProvider: body1TextProvider,
            body2TextProvider: body2TextProvider)
    }
}
