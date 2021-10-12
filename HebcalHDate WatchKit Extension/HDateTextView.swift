//
//  HDateTextView.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 10/12/21.
//

import Foundation
import SwiftUI

struct HDateTextView: View {
    var day: String
    var month: String
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.08, green: 0.08, blue: 0.08))
            VStack(spacing: 0) {
                Text(day)
                    .offset(x: 0, y: -2)
                    .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.0))
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    .scaledToFill()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(month)
                    .offset(x: 0, y: -2)
                    .foregroundColor(.white)
                    .font(.system(size: 10, weight: .semibold, design: .default))
                    .scaledToFill()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                }
            .multilineTextAlignment(.center)
        }
    }
}

struct HDateTextView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HDateTextView(day: "26", month: "Tishrei")
            HDateTextView(day: "6", month: "Cheshv")
            HDateTextView(day: "ט״ז", month: "אדר א׳")
            HDateTextView(day: "ט״ז", month: "תמוז")
            HDateTextView(day: "י״ד", month: "אב")
        }
        .previewLayout(.fixed(width: 44, height: 44))
    }
}
