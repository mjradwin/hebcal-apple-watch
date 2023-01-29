//
//  HDateTextView.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 10/12/21.
//

import Foundation
import SwiftUI
import WatchKit
import ClockKit

struct HDateTextView: View {
    @Environment(\.complicationRenderingMode) var renderingMode

    var day: String
    var month: String
    var complicationSize: CGFloat {
        let screenHeight = WKInterfaceDevice.current().screenBounds.size.height
        if screenHeight >= 251 {
            // The Apple Watch Ultra 49mm case size
            return 108
        } else if screenHeight >= 242 {
            // Apple Watch 45mm
            return 100
        } else if screenHeight >= 224 {
            return 94 // 44mm case
        } else if screenHeight >= 215 {
            return 89 // 41mm case
        } else if screenHeight >= 197 {
            return 84 // 40mm case
        } else if screenHeight >= 195 {
            return 90 // 42mm case
        } else if screenHeight >= 170 {
            return 80 // 38mm case
        }
        return 84    // Fallback, just in case.

    }
    var dayFontSize: CGFloat {
        let n = day.hasSuffix("׳") ? 30 : day.count == 1 ? 27.5 : 23
        return n * (complicationSize / 100.0)
    }
    var body: some View {
        ZStack {
            if renderingMode == .fullColor {
                Circle()
                    .fill(Color(red: 0.11, green: 0.10, blue: 0.08))
            }
            VStack(spacing: 0) {
                Text(day)
                    .offset(x: 0, y: -2)
                    .foregroundColor(.primary)
                    .font(.system(size: dayFontSize, weight: .semibold, design: .default))
                    .scaledToFill()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(month)
                    .offset(x: 0, y: -5)
                    .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.0))
                    .font(.system(size: 12, weight: .semibold, design: .default))
                    .scaledToFill()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .complicationForeground()
        }
    }
}

struct HDateTextView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CLKComplicationTemplateGraphicCircularView(HDateTextView(day: "29", month: "Tishr")).previewContext()
            CLKComplicationTemplateGraphicCircularView(HDateTextView(day: "30", month: "Chesh")).previewContext()
            CLKComplicationTemplateGraphicCircularView(HDateTextView(day: "16", month: "Kislev")).previewContext()
            CLKComplicationTemplateGraphicCircularView(HDateTextView(day: "3", month: "Adar2")).previewContext()
            CLKComplicationTemplateGraphicCircularView(HDateTextView(day: "7", month: "Shvat")).previewContext()
            CLKComplicationTemplateGraphicCircularView(HDateTextView(day: "ט״ז", month: "אדר א׳")).previewContext()
            CLKComplicationTemplateGraphicCircularView(HDateTextView(day: "א׳", month: "אדר א׳")).previewContext()
            CLKComplicationTemplateGraphicCircularView(HDateTextView(day: "ט״ז", month: "תמוז")).previewContext()
            CLKComplicationTemplateGraphicCircularView(HDateTextView(day: "י״ד", month: "אב")).previewContext(faceColor: .red)
            CLKComplicationTemplateGraphicCircularView(HDateTextView(day: "7", month: "Shvat"))
                .previewContext()
                .previewDevice(PreviewDevice(rawValue: "Apple Watch Series 3 - 42mm"))
                .previewDevice("42 mm")

        }
    }
}
