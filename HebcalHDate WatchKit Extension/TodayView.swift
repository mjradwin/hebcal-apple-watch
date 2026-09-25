//
//  TodayView.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 9/30/21.
//

import Foundation
import SwiftUI
import Hebcal

struct TodayView: View {
    @ScaledMetric private var smallFontSize: CGFloat = 16
    @ScaledMetric private var largeFontSize: CGFloat = 18
    var item: DateItem
    var gregDate: String {
        var s = item.dow + ", " + String(item.gregDay) + " " + item.gregMonth
        if item.gregYear != 0 {
            s += " " + String(item.gregYear)
        }
        if item.emoji != nil {
            s += "  " + item.emoji!
        }
        return s
    }
    var isHebrew: Bool {
        item.lang == .he
    }
    var body: some View {
        HStack {
            if isHebrew {
                Spacer()
            }
            VStack(alignment: isHebrew ? .trailing : .leading, spacing:0) {
                Text(gregDate)
                    .foregroundColor(.secondary)
                    .font(.system(size: smallFontSize, weight: .regular, design: .default))
                    .lineLimit(1)
                Text(item.hdate)
                    .foregroundColor(.white)
                    .font(.system(size: largeFontSize, weight: .regular, design: .default))
                    .lineLimit(1)
                ForEach(item.holidays, id: \.self) { holiday in
                    Text(holiday)
                        .foregroundColor(.yellow)
                        .font(.system(size: largeFontSize, weight: .regular, design: .default))
                        .lineLimit(holiday.count > 19 ? 2 : 1)
                }
                item.omer.map({
                    Text($0)
                        .foregroundColor(.secondary)
                        .font(.system(size: smallFontSize, weight: .regular, design: .default))
                        .lineLimit(1)
                })
                if item.parsha != nil {
                    HStack {
                        Image("torah-235339")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                        Text(item.parsha!)
                            .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.0))
                            .font(.system(size: largeFontSize, weight: .regular, design: .default))
                            .lineLimit(1)
                    }
                }
                if item.dafyomi != nil {
                    Text(item.dafyomi!)
                        .foregroundColor(.secondary)
                        .font(.system(size: smallFontSize, weight: .regular, design: .default))
                        .lineLimit(1)
                }
            }
            .minimumScaleFactor(0.6)
            .multilineTextAlignment(isHebrew ? .trailing : .leading)
        }
    }
}


struct TodayView_Previews: PreviewProvider {
    static var item = DateItem(
         id: 1,
         lang: .en,
         dow: "Wed", gregDay: 28, gregMonth: "Apr",
         gregYear: 2021,
         hdate: "16 Iyyar 5782", parsha: "Emor",
         holidays: ["Lag BaOmer"],
         emoji: "😀",
         omer: "Omer: 31st day",
         dafyomi: "Pesachim 108"
    )

    static var previews: some View {
        TodayView(item: item)
            .previewLayout(.fixed(width: 300, height: 150))
    }
}
