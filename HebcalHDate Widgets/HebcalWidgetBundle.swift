//
//  HebcalWidgetBundle.swift
//  HebcalHDate Widgets
//
//  Three widgets, one for each of the original ClockKit complications:
//
//    complicationHebcal  -> rich rectangular + inline
//    complicationHdate   -> small day/month (circular, corner, inline)
//    complicationParsha  -> Torah portion (circular, inline)
//
//  The `kind` strings are preserved from the legacy
//  CLKComplicationDescriptor identifiers so users that had a Hebcal
//  complication configured before the migration get matched to the
//  equivalent widget by WidgetKit's complications migrator.
//

import SwiftUI
import WidgetKit

@main
struct HebcalWidgetBundle: WidgetBundle {
    var body: some Widget {
        HebcalWidget()
        HDateWidget()
        ParshaWidget()
    }
}

struct HebcalWidget: Widget {
    let kind: String = "complicationHebcal"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HebcalProvider()) { entry in
            HebcalWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Hebcal")
        .description("Hebrew date, Torah portion, and holidays")
        .supportedFamilies([.accessoryRectangular, .accessoryInline])
    }
}

struct HDateWidget: Widget {
    let kind: String = "complicationHdate"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HebcalProvider()) { entry in
            HDateWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Hebrew Date")
        .description("Today's date in the Hebrew calendar")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryInline])
    }
}

struct ParshaWidget: Widget {
    let kind: String = "complicationParsha"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HebcalProvider()) { entry in
            ParshaWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Torah Portion")
        .description("Weekly Torah portion")
        .supportedFamilies([.accessoryCircular, .accessoryInline])
    }
}
