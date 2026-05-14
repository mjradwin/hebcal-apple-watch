//
//  HebcalWidgetViews.swift
//  HebcalHDate Widgets
//
//  SwiftUI views for each accessory family. The big design goals carried
//  forward from the ClockKit version:
//    * Circular face shows day-on-top, month-below.
//    * Corner face has the month near the inside and the day curving
//      along the outer edge.
//    * Inline mirrors the old utilitarianSmallFlat / utilitarianLargeFlat
//      strings.
//    * Rectangular mirrors the old graphic-rectangular three-line body.
//

import SwiftUI
import WidgetKit

private let goldTint = Color(red: 1.0, green: 0.75, blue: 0.0)

// MARK: - Hebrew date

/// Accessory circular: big day number, gold month below. Adapted from
/// the legacy HDateTextView so the typography matches what users see
/// today.
struct HDateCircularView: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    let day: String
    let month: String

    private var dayFontSize: CGFloat {
        if day.hasSuffix("׳") { return 30 }
        return day.count == 1 ? 27.5 : 23
    }

    var body: some View {
        ZStack {
            if renderingMode == .fullColor {
                Circle().fill(Color(red: 0.11, green: 0.10, blue: 0.08))
            }
            VStack(spacing: 0) {
                Text(day)
                    .offset(x: 0, y: -2)
                    .foregroundColor(.white)
                    .font(.system(size: dayFontSize, weight: .semibold))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(month)
                    .offset(x: 0, y: -5)
                    .foregroundColor(goldTint)
                    .font(.system(size: 12, weight: .semibold))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .widgetAccentable()
        }
    }
}

/// Accessory corner: month text near the centre with the day number
/// curving along the bezel via `.widgetLabel`.
struct HDateCornerView: View {
    let day: String
    let month: String

    var body: some View {
        Text(month)
            .font(.system(size: 14, weight: .semibold))
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .widgetLabel(day)
    }
}

/// Accessory rectangular: header (date + emoji), body1 (holiday/parsha),
/// body2 (parsha/omer). Matches the legacy graphic-rectangular layout.
struct HebcalRectangularView: View {
    let entry: HebcalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(entry.richHeaderLong)
                .font(.headline)
                .foregroundColor(goldTint)
                .widgetAccentable()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(entry.richBody1)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let body2 = entry.richBody2 {
                Text(body2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Parsha

/// Accessory circular for Torah portion: 1 or 2 stacked lines.
struct ParshaCircularView: View {
    let parts: [String]

    var body: some View {
        if parts.count >= 2 {
            VStack(spacing: 0) {
                Text(parts[0])
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(parts[1])
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .widgetAccentable()
        } else {
            Text(parts.first ?? "")
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .widgetAccentable()
        }
    }
}

// MARK: - Container views

struct HebcalWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HebcalEntry

    @ViewBuilder
    var body: some View {
        switch family {
        case .accessoryRectangular:
            HebcalRectangularView(entry: entry)
        case .accessoryInline:
            Text(entry.inlineText)
        default:
            // The Hebcal widget only declares rectangular+inline, but
            // be defensive for forward-compat.
            Text(entry.hebDateShort)
        }
    }
}

struct HDateWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HebcalEntry

    @ViewBuilder
    var body: some View {
        switch family {
        case .accessoryCircular:
            HDateCircularView(day: entry.hebDayNumber, month: entry.hebMonthAbbrev)
        case .accessoryCorner:
            HDateCornerView(day: entry.hebDayNumber, month: entry.hebMonthAbbrev)
        case .accessoryInline:
            Text(entry.hebDateShort)
        default:
            Text(entry.hebDateShort)
        }
    }
}

struct ParshaWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HebcalEntry

    @ViewBuilder
    var body: some View {
        switch family {
        case .accessoryCircular:
            ParshaCircularView(parts: entry.parshaParts)
        case .accessoryInline:
            Text(entry.parshaPrefixed)
        default:
            Text(entry.parshaParts.first ?? "")
        }
    }
}
