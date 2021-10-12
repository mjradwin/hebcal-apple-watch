//
//  HDateTextView.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 10/12/21.
//

import Foundation
import SwiftUI
import ClockKit

struct HDateTextView: View {
    @Environment(\.complicationRenderingMode) var renderingMode

    var day: String
    var month: String
    var body: some View {
        ZStack {
            if renderingMode == .fullColor {
                Circle()
                    .fill(Color(red: 0.08, green: 0.08, blue: 0.08))
            }
            VStack(spacing: 0) {
                Text(day)
                    .foregroundColor(.primary)
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    .scaledToFill()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(month)
                    .offset(x: 0, y: -3)
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
            CLKComplicationTemplateGraphicCircularView(HDateTextView(day: "26", month: "Tishr")).previewContext()
            CLKComplicationTemplateGraphicCircularView(HDateTextView(day: "30", month: "Chesh")).previewContext()
            CLKComplicationTemplateGraphicCircularView(HDateTextView(day: "16", month: "Kislev")).previewContext()
            CLKComplicationTemplateGraphicCircularView(HDateTextView(day: "3", month: "Adar2")).previewContext()
            CLKComplicationTemplateGraphicCircularView(HDateTextView(day: "ט״ז", month: "אדר א׳")).previewContext()
            CLKComplicationTemplateGraphicCircularView(HDateTextView(day: "ט״ז", month: "תמוז")).previewContext()
            CLKComplicationTemplateGraphicCircularView(HDateTextView(day: "י״ד", month: "אב")).previewContext(faceColor: .red)
        }
    }
}
