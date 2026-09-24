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

    let entry: HebcalEntry

    private var dayFontSize: CGFloat {
        if entry.hebDayNumber.hasSuffix("׳") { return 30 }
        return entry.hebDayNumber.count == 1 ? 27.5 : 23
    }

    var body: some View {
        ZStack {
            if renderingMode == .fullColor {
                Circle().fill(Color(red: 0.11, green: 0.10, blue: 0.08))
            }
            VStack(spacing: 0) {
                Text(entry.hebDayNumber)
                    .offset(x: 0, y: -2)
                    .foregroundColor(.white)
                    .font(.system(size: dayFontSize, weight: .semibold))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(entry.hebMonthAbbrev)
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

/// Accessory corner: large day number near the centre with the month
/// curving along the bezel via `.widgetLabel`.
struct HDateCornerView: View {
    let entry: HebcalEntry

    var body: some View {
        Text(entry.hebDayNumber)
            .widgetCurvesContent()
            .foregroundColor(.white)
            .lineLimit(1)
            .widgetLabel {
                Text(entry.hebMonthName)
                    .foregroundColor(goldTint)
            }
    }
}

/// Accessory rectangular: header (date + emoji), body1 (holiday/parsha),
/// body2 (parsha/omer). Matches the legacy graphic-rectangular layout.
struct HebcalRectangularView: View {
    let entry: HebcalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ViewThatFits(in: .horizontal) {
                Text(entry.richHeaderLong)
                Text(entry.richHeaderShort)
            }
            .font(.headline)
            .foregroundColor(.primary)
            .widgetAccentable()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            if entry.holidayToday != nil {
                ViewThatFits(in: .horizontal) {
                    Text(entry.holidayToday!)
                    Text(entry.holidayShort!)
                }
                .foregroundColor(.yellow)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            }
            if entry.parshaName != nil {
                HStack {
                    Image("torah-235339")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text(entry.parshaName!)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .foregroundColor(goldTint)
                }
            } else if entry.holidayToday == nil {
                // Show the Torah icon before upcoming Shabbat holiday
                HStack {
                    Image("torah-235339")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text(entry.parshaForFallback)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .foregroundColor(goldTint)
                }
            }
            if entry.omerToday != nil {
                Text(entry.omerToday!)
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
    let entry: HebcalEntry

    var body: some View {
        let parts = entry.parshaParts
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
            ViewThatFits(in: .horizontal) {
                Text(entry.inlineText)
                Text(entry.inlineShortText ?? entry.inlineText)
            }
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
            HDateCircularView(entry: entry)
        case .accessoryCorner:
            HDateCornerView(entry: entry)
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
            ParshaCircularView(entry: entry)
        case .accessoryInline:
            ViewThatFits(in: .horizontal) {
                Text(entry.parshaPrefixed)
                Text(entry.parshaForFallback)
            }
        default:
            Text(entry.parshaParts.first ?? "")
        }
    }
}

// MARK: - Previews

#if DEBUG
/// Noon local time on the given Gregorian date, so `makeHDate`'s 8pm
/// day-rollover never pushes the preview onto the next Hebrew day.
private func previewNoon(year: Int, month: Int, day: Int) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = 12
    return Calendar(identifier: .gregorian).date(from: components)!
}

// Compares the ParshaCircularView fix directly: Sep 21, 2026 is Yom Kippur
// (a holiday, not Shabbat) and used to wrongly show the upcoming
// "Parashat Sukkot"; Sep 22 is an ordinary day between Yom Kippur and
// Sukkot and still correctly shows the upcoming weekly parsha.
#Preview("Yom Kippur — Sep 21, 2026", as: .accessoryCircular) {
    ParshaWidget()
} timeline: {
    HebcalProvider.makeEntry(for: previewNoon(year: 2026, month: 9, day: 21))
}

#Preview("YK — Rectangular", as: .accessoryRectangular) {
    HebcalWidget()
} timeline: {
    HebcalProvider.makeEntry(for: previewNoon(year: 2026, month: 9, day: 21))
}

#Preview("RCh Chanukah weekday — Rectangular", as: .accessoryRectangular) {
    HebcalWidget()
} timeline: {
    HebcalProvider.makeEntry(for: previewNoon(year: 2026, month: 12, day: 10))
}

#Preview("Pesach VI (CH’’M) — Rectangular", as: .accessoryRectangular) {
    HebcalWidget()
} timeline: {
    HebcalProvider.makeEntry(for: previewNoon(year: 2027, month: 4, day: 27))
}

#Preview("Day after — Sep 22, 2026", as: .accessoryCircular) {
    ParshaWidget()
} timeline: {
    HebcalProvider.makeEntry(for: previewNoon(year: 2026, month: 9, day: 22))
}

// Oct 7, 2026 = 26 Tishrei 5787, an ordinary day just after Sukkot/Simchat
// Torah — exercises the other two widgets' non-holiday rendering.
#Preview("Oct 7, 2026 — Rectangular", as: .accessoryRectangular) {
    HebcalWidget()
} timeline: {
    HebcalProvider.makeEntry(for: previewNoon(year: 2026, month: 10, day: 7))
}

#Preview("Oct 7, 2026 — Inline", as: .accessoryInline) {
    HebcalWidget()
} timeline: {
    HebcalProvider.makeEntry(for: previewNoon(year: 2026, month: 10, day: 7))
}

#Preview("Oct 7, 2026 — HDate Circular", as: .accessoryCircular) {
    HDateWidget()
} timeline: {
    HebcalProvider.makeEntry(for: previewNoon(year: 2026, month: 10, day: 7))
}

#Preview("Oct 7, 2026 — HDate Corner", as: .accessoryCorner) {
    HDateWidget()
} timeline: {
    HebcalProvider.makeEntry(for: previewNoon(year: 2026, month: 10, day: 7))
}

#Preview("Oct 7, 2026 — HDate Inline", as: .accessoryInline) {
    HDateWidget()
} timeline: {
    HebcalProvider.makeEntry(for: previewNoon(year: 2026, month: 10, day: 7))
}

#Preview("Oct 7, 2026 — Parsha Circular", as: .accessoryCircular) {
    ParshaWidget()
} timeline: {
    HebcalProvider.makeEntry(for: previewNoon(year: 2026, month: 10, day: 7))
}
#endif
