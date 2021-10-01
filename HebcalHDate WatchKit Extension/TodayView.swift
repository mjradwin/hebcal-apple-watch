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
    var item: DateItem
    var gregDate: String {
        var s = item.dow + ", " + String(item.gregDay) + " " + item.gregMonth
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
            VStack(alignment: isHebrew ? .trailing : .leading) {
                Text(gregDate)
                    .foregroundColor(.gray)
                    .scaledFont(size: 16, weight: .regular, design: .default)
                    .lineLimit(1)
                Text(item.hdate)
                    .foregroundColor(.white)
                    .scaledFont(size: 18, weight: .regular, design: .default)
                    .lineLimit(1)
                ForEach(item.holidays, id: \.self) { holiday in
                    Text(holiday)
                        .foregroundColor(.yellow)
                        .scaledFont(size: 18, weight: .regular, design: .default)
                        .lineLimit(holiday.count > 19 ? 2 : 1)
                }
                item.omer.map({
                    Text($0)
                        .foregroundColor(.gray)
                        .scaledFont(size: 16, weight: .regular, design: .default)
                        .lineLimit(1)
                })
                if item.parsha != nil {
                    HStack {
                        Image("torah-orange")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                        Text(item.parsha!)
                            .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.0))
                            .scaledFont(size: 18, weight: .regular, design: .default)
                            .lineLimit(1)
                    }
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
         weekday: 1, dow: "Wed", gregDay: 28, gregMonth: "Apr",
         hdate: "16 Iyyar 5782", parsha: "Emor",
         holidays: ["Lag BaOmer"],
         emoji: "😀",
         omer: "Omer: 31st day"
    )

    static var previews: some View {
        TodayView(item: item)
            .previewLayout(.fixed(width: 300, height: 150))
    }
}
