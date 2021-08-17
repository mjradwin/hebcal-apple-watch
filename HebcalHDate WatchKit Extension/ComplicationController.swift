//
//  ComplicationController.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 8/17/21.
//

import ClockKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    
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

    // MARK: - Timeline Configuration
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Call the handler with the last entry date you can currently provide or nil if you can't support future timelines
        handler(nil)
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
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries after the given date
        handler(nil)
    }

    // MARK: - Sample Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        handler(nil)
    }

    var cal2 = Calendar(identifier: Calendar.Identifier.hebrew)
    
    // Return a timeline entry for the specified complication and date.
    private func createTimelineEntry(forComplication complication: CLKComplication, date: Date) -> CLKComplicationTimelineEntry {
        
        // Get the correct template based on the complication.
        let template = createTemplate(forComplication: complication, date: date)
        
        // Use the template and date to create a timeline entry.
        return CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
    }
    
    // Select the correct template based on the complication's family.
    private func createTemplate(forComplication complication: CLKComplication, date: Date) -> CLKComplicationTemplate {
        switch complication.family {
        case .modularSmall:
            return createModularSmallTemplate(forDate: date)
        case .modularLarge:
            fatalError("*** Unsupported Complication Family ***")
        case .utilitarianSmall, .utilitarianSmallFlat:
            return createUtilitarianSmallFlatTemplate(forDate: date)
        case .utilitarianLarge:
            return createUtilitarianLargeTemplate(forDate: date)
        case .circularSmall:
            return createCircularSmallTemplate(forDate: date)
        case .graphicCorner:
            return createGraphicCornerTemplate(forDate: date)
        case .graphicCircular:
            return createGraphicCircleTemplate(forDate: date)
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

    private func getHebDateString(forDate date: Date) -> String {
        let hebrewCalendar = Calendar(identifier: Calendar.Identifier.hebrew)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.calendar = hebrewCalendar
        return dateFormatter.string(from: date)
    }
    
    // Return a modular small template.
    private func createModularSmallTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let hebDateStr = getHebDateString(forDate: date)
        let parts = hebDateStr.split(separator: " ")
        // Create the data providers.
        let dayNumberProvider = CLKSimpleTextProvider(text: String(parts[0]))
        let monthNameProvider = CLKSimpleTextProvider(text: String(parts[1]))
        
        // Create the template using the providers.
        return CLKComplicationTemplateModularSmallStackText(line1TextProvider: dayNumberProvider,
                                                            line2TextProvider: monthNameProvider)
    }
    
    // Return a utilitarian small flat template.
    private func createUtilitarianSmallFlatTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let hebDateStr = getHebDateString(forDate: date)
        let parts = hebDateStr.split(separator: " ")
        let dayNumberProvider = CLKSimpleTextProvider(text: String(parts[0]))
        let monthNameProvider = CLKSimpleTextProvider(text: String(parts[1]))
        let combinedProvider = CLKTextProvider(format: "%@ %@", dayNumberProvider, monthNameProvider)

        // Create the template using the providers.
        return CLKComplicationTemplateUtilitarianSmallFlat(textProvider: combinedProvider)
    }
    
    // Return a utilitarian large template.
    private func createUtilitarianLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let hebDateStr = getHebDateString(forDate: date)
        let hebDateProvider = CLKSimpleTextProvider(text: hebDateStr)
        // Create the template using the providers.
        return CLKComplicationTemplateUtilitarianLargeFlat(textProvider: hebDateProvider)
    }
    
    // Return a circular small template.
    private func createCircularSmallTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let hebDateStr = getHebDateString(forDate: date)
        let parts = hebDateStr.split(separator: " ")
        // Create the data providers.
        let dayNumberProvider = CLKSimpleTextProvider(text: String(parts[0]))
        let monthNameProvider = CLKSimpleTextProvider(text: String(parts[1]))

        // Create the template using the providers.
        return CLKComplicationTemplateCircularSmallStackText(line1TextProvider: dayNumberProvider,
                                                             line2TextProvider: monthNameProvider)
    }
        
    // Return a graphic template that fills the corner of the watch face.
    private func createGraphicCornerTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let hebDateStr = getHebDateString(forDate: date)
        let hebDateProvider = CLKSimpleTextProvider(text: hebDateStr)
        let labelProvider = CLKSimpleTextProvider(text: "Today")
        // Create the template using the providers.
        return CLKComplicationTemplateGraphicCornerStackText(innerTextProvider: hebDateProvider,
                                                             outerTextProvider: labelProvider)
    }
    
    // Return a graphic circle template.
    private func createGraphicCircleTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let hebDateStr = getHebDateString(forDate: date)
        let parts = hebDateStr.split(separator: " ")
        let dayNumberProvider = CLKSimpleTextProvider(text: String(parts[0]))
        let monthNameProvider = CLKSimpleTextProvider(text: String(parts[1]))
        // Create the template using the providers.
        return CLKComplicationTemplateGraphicCircularStackText(line1TextProvider: dayNumberProvider,
                                                               line2TextProvider: monthNameProvider)
    }
}
