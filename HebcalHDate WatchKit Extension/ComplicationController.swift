//
//  ComplicationController.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 8/17/21.
//

import ClockKit
import os
import Hebcal

class ComplicationController: NSObject, CLKComplicationDataSource {
    lazy var settings = ModelData.shared
    let logger = Logger(subsystem: "com.hebcal.HebcalHDate.watchkitapp.watchkitextension.ComplicationController", category: "Root View")

    // MARK: - Complication Configuration

    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let mySupportedFamilies = [CLKComplicationFamily.modularSmall,
                                   CLKComplicationFamily.circularSmall,
                                   CLKComplicationFamily.utilitarianSmall,
                                   CLKComplicationFamily.utilitarianSmallFlat,
                                   CLKComplicationFamily.utilitarianLarge,
                                   CLKComplicationFamily.graphicCorner,
                                   CLKComplicationFamily.graphicCircular
        ];
        let descriptors = [
            CLKComplicationDescriptor(identifier: "complicationHdate", displayName: "Hebrew Date", supportedFamilies: mySupportedFamilies),
            CLKComplicationDescriptor(identifier: "complicationParsha", displayName: "Torah Portion", supportedFamilies: mySupportedFamilies)
            // Multiple complication support can be added here with more descriptors
        ]
        
        // Call the handler with the currently supported complication descriptors
        handler(descriptors)
    }
    
    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
        // Do any necessary work to support these newly shared complication descriptors
    }

    let twentyFourHours = 24.0 * 60.0 * 60.0
    let oneWeek = 7.0 * 24.0 * 60.0 * 60.0

    // MARK: - Timeline Configuration

    // Define how far into the future the app can provide data.
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Indicate that the app can provide timeline entries for the next 30 days
        let endDate = Date().addingTimeInterval(oneWeek)
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
        var current = date.addingTimeInterval(twentyFourHours)
        let endDate = date.addingTimeInterval(oneWeek)
    
        // Create a timeline entry for every 24h from the starting time.
        // Stop once you reach the limit or the end date.
        while (current.compare(endDate) == .orderedAscending) && (entries.count < limit) {
            logger.debug("getTimelineEntries \(current)")
            entries.append(createTimelineEntry(forComplication: complication, date: current))
            current = current.addingTimeInterval(twentyFourHours)
        }
        handler(entries)
    }

    // MARK: - Sample Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        switch complication.family {
        case .modularSmall, .utilitarianSmall, .utilitarianSmallFlat, .utilitarianLarge, .circularSmall, .graphicCorner, .graphicCircular:
            let template = complication.identifier == "complicationHdate" ?
                    createHDateTemplate(forComplication: complication, date: Date()) :
                    createParshaTemplate(forComplication: complication, date: Date())
            handler(template)
        case .modularLarge, .extraLarge, .graphicRectangular, .graphicBezel, .graphicExtraLarge:
            handler(nil)
        @unknown default:
            fatalError("*** Unknown Complication Family ***")
        }
    }

    var cal2 = Calendar(identifier: Calendar.Identifier.hebrew)

    // Return a timeline entry for the specified complication and date.
    private func createTimelineEntry(forComplication complication: CLKComplication, date: Date) -> CLKComplicationTimelineEntry {

        // Get the correct template based on the complication.
        let template = complication.identifier == "complicationHdate" ?
                createHDateTemplate(forComplication: complication, date: date) :
                createParshaTemplate(forComplication: complication, date: date)

        // Use the template and date to create a timeline entry.
        return CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
    }

    // Select the correct template based on the complication's family.
    private func createParshaTemplate(forComplication complication: CLKComplication, date: Date) -> CLKComplicationTemplate {
        switch complication.family {
        case .modularSmall:
            return createParshaModularSmallTemplate(forDate: date)
        case .modularLarge:
            fatalError("*** Unsupported Complication Family ***")
        case .utilitarianSmall, .utilitarianSmallFlat:
            return createParshaUtilitarianSmallFlatTemplate(forDate: date)
        case .utilitarianLarge:
            return createParshaUtilitarianLargeTemplate(forDate: date)
        case .circularSmall:
            return createParshaCircularSmallTemplate(forDate: date)
        case .graphicCorner:
            return createParshaGraphicCornerTemplate(forDate: date)
        case .graphicCircular:
            return createParshaGraphicCircleTemplate(forDate: date)
        case .extraLarge:
            fatalError("*** Unsupported Complication Family ***")
        case .graphicRectangular:
            fatalError("*** Unsupported Complication Family ***")
        case .graphicBezel:
            fatalError("*** Unsupported Complication Family ***")
        case .graphicExtraLarge:
            fatalError("*** Unsupported Complication Family ***")
        @unknown default:
            fatalError("*** Unknown Complication Family ***")
        }
    }

    private func createHDateTemplate(forComplication complication: CLKComplication, date: Date) -> CLKComplicationTemplate {
        switch complication.family {
        case .modularSmall:
            return createHDateModularSmallTemplate(forDate: date)
        case .modularLarge:
            fatalError("*** Unsupported Complication Family ***")
        case .utilitarianSmall, .utilitarianSmallFlat:
            return createHDateUtilitarianSmallFlatTemplate(forDate: date)
        case .utilitarianLarge:
            return createHDateUtilitarianLargeTemplate(forDate: date)
        case .circularSmall:
            return createHDateCircularSmallTemplate(forDate: date)
        case .graphicCorner:
            return createHDateGraphicCornerTemplate(forDate: date)
        case .graphicCircular:
            return createHDateGraphicCircleTemplate(forDate: date)
        case .extraLarge:
            fatalError("*** Unsupported Complication Family ***")
        case .graphicRectangular:
            fatalError("*** Unsupported Complication Family ***")
        case .graphicBezel:
            fatalError("*** Unsupported Complication Family ***")
        case .graphicExtraLarge:
            fatalError("*** Unsupported Complication Family ***")
        @unknown default:
            fatalError("*** Unknown Complication Family ***")
        }
    }

    // Return a modular small template.
    private func createHDateModularSmallTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let hebDateStr = getHebDateString(forDate: date)
        let parts = hebDateStr.split(separator: " ")
        // Create the data providers.
        let dayNumberProvider = CLKSimpleTextProvider(text: String(parts[0]))
        dayNumberProvider.tintColor = .red
        let monthNameProvider = CLKSimpleTextProvider(text: String(parts[1]))
        
        // Create the template using the providers.
        return CLKComplicationTemplateModularSmallStackText(line1TextProvider: dayNumberProvider,
                                                            line2TextProvider: monthNameProvider)
    }
    
    // Return a utilitarian small flat template.
    private func createHDateUtilitarianSmallFlatTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let hebDateStr = getHebDateString(forDate: date)
        let parts = hebDateStr.split(separator: " ")
        let dayNumberProvider = CLKSimpleTextProvider(text: String(parts[0]))
        dayNumberProvider.tintColor = .red
        let monthNameProvider = CLKSimpleTextProvider(text: String(parts[1]))
        let combinedProvider = CLKTextProvider(format: "%@ %@", dayNumberProvider, monthNameProvider)

        // Create the template using the providers.
        return CLKComplicationTemplateUtilitarianSmallFlat(textProvider: combinedProvider)
    }
    
    // Return a utilitarian large template.
    private func createHDateUtilitarianLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let hebDateStr = getHebDateString(forDate: date)
        let hebDateProvider = CLKSimpleTextProvider(text: hebDateStr)
        // Create the template using the providers.
        return CLKComplicationTemplateUtilitarianLargeFlat(textProvider: hebDateProvider)
    }
    
    // Return a circular small template.
    private func createHDateCircularSmallTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let hebDateStr = getHebDateString(forDate: date)
        let parts = hebDateStr.split(separator: " ")
        // Create the data providers.
        let dayNumberProvider = CLKSimpleTextProvider(text: String(parts[0]))
        dayNumberProvider.tintColor = .red
        let monthNameProvider = CLKSimpleTextProvider(text: String(parts[1]))

        // Create the template using the providers.
        return CLKComplicationTemplateCircularSmallStackText(line1TextProvider: dayNumberProvider,
                                                             line2TextProvider: monthNameProvider)
    }
        
    // Return a graphic template that fills the corner of the watch face.
    private func createHDateGraphicCornerTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let hebDateStr = getHebDateString(forDate: date)
        let hebDateProvider = CLKSimpleTextProvider(text: hebDateStr)
        let labelProvider = CLKSimpleTextProvider(text: "Today")
        // Create the template using the providers.
        return CLKComplicationTemplateGraphicCornerStackText(innerTextProvider: hebDateProvider,
                                                             outerTextProvider: labelProvider)
    }

    // Return a graphic circle template.
    private func createHDateGraphicCircleTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let hebDateStr = getHebDateString(forDate: date)
        let parts = hebDateStr.split(separator: " ")
        let dayNumberProvider = CLKSimpleTextProvider(text: String(parts[0]))
        dayNumberProvider.tintColor = .red
        let monthNameProvider = CLKSimpleTextProvider(text: String(parts[1]))
        // Create the template using the providers.
        return CLKComplicationTemplateGraphicCircularStackText(line1TextProvider: dayNumberProvider,
                                                               line2TextProvider: monthNameProvider)
    }

    // Return a modular small template.
    private func createParshaModularSmallTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let parsha = getParshaString(date: date, il: settings.il)
        // Create the data providers.
        let parshaProvider = CLKSimpleTextProvider(text: "Parashat")
        let parshaNameProvider = CLKSimpleTextProvider(text: parsha)

        // Create the template using the providers.
        return CLKComplicationTemplateModularSmallStackText(line1TextProvider: parshaProvider,
                                                            line2TextProvider: parshaNameProvider)
    }

    // Return a utilitarian small flat template.
    private func createParshaUtilitarianSmallFlatTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let flatUtilitarianImageProvider = CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "Torah_964497"))
        let parsha = getParshaString(date: date, il: settings.il)
        // Create the data providers.
        let parshaNameProvider = CLKSimpleTextProvider(text: parsha)
        // Create the template using the providers.
        return CLKComplicationTemplateUtilitarianSmallFlat(textProvider: parshaNameProvider,
                                                           imageProvider: flatUtilitarianImageProvider)
    }

    // Return a utilitarian large template.
    private func createParshaUtilitarianLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let flatUtilitarianImageProvider = CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "Torah_964497"))
        let parsha = getParshaString(date: date, il: settings.il)
        let parshaNameProvider = CLKSimpleTextProvider(text: parsha)
        let parshaStrProvider = CLKTextProvider(format: "Parashat %@", parshaNameProvider)
        // Create the template using the providers.
        return CLKComplicationTemplateUtilitarianLargeFlat(textProvider: parshaStrProvider,
                                                           imageProvider: flatUtilitarianImageProvider)
    }

    // Return a circular small template.
    private func createParshaCircularSmallTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let parsha = getParshaString(date: date, il: settings.il)
        // Create the data providers.
        let labelProvider = CLKSimpleTextProvider(text: "Parashat")
        let parshaNameProvider = CLKSimpleTextProvider(text: parsha)

        // Create the template using the providers.
        return CLKComplicationTemplateCircularSmallStackText(line1TextProvider: labelProvider,
                                                             line2TextProvider: parshaNameProvider)
    }

    // Return a graphic template that fills the corner of the watch face.
    private func createParshaGraphicCornerTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let parsha = getParshaString(date: date, il: settings.il)
        let parshaNameProvider = CLKSimpleTextProvider(text: parsha)
        let imageProvider = CLKFullColorImageProvider(fullColorImage: #imageLiteral(resourceName: "torah-orange"))
        // Create the template using the providers.
        return CLKComplicationTemplateGraphicCornerTextImage(textProvider: parshaNameProvider,
                                                             imageProvider: imageProvider)
    }

    // Return a graphic circle template.
    private func createParshaGraphicCircleTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let parsha = getParshaString(date: date, il: settings.il)
        // Create the data providers.
        let labelProvider = CLKSimpleTextProvider(text: "Parashat")
        let parshaNameProvider = CLKSimpleTextProvider(text: parsha)
        // Create the template using the providers.
        return CLKComplicationTemplateGraphicCircularStackText(line1TextProvider: labelProvider,
                                                               line2TextProvider: parshaNameProvider)
    }
}
