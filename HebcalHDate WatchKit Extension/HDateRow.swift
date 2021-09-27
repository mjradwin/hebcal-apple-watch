//
//  HDateRow.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 9/5/21.
//

import Foundation
import SwiftUI
import Hebcal

struct HDateRow: View {
    var item: DateItem
    var lang: TranslationLang {
        item.lang
    }
    var textAlignment: TextAlignment {
        (item.lang == .he) ? .trailing : .leading
    }
    var stackAlignment: HorizontalAlignment {
        (item.lang == .he) ? .trailing : .leading
    }

    var body: some View {
        HStack {
            VStack {
                Text(item.dow)
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundColor(.white)
                Text(String(item.gregDay))
                    .font(.system(size: 20, weight: .semibold, design: .monospaced))
                    .foregroundColor(.orange)
                Text(item.gregMonth)
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundColor(.gray)
            }
            .padding(.leading, 2.0)
            if lang == .he {
                Spacer()
            }
            VStack(alignment: stackAlignment) {
                Text(item.hdate)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .multilineTextAlignment(textAlignment)
                item.parsha.map({
                    Text($0)
                        .font(.system(size: (lang == .he) ? 16 : 14,
                                      weight: .regular, design: .default))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(textAlignment)
                })
                ForEach(item.holidays, id: \.self) { holiday in
                    Text(holiday)
                        .font(.system(size: (lang == .he) ? 16 : 14,
                                      weight: .regular, design: .default))
                        .foregroundColor(.yellow)
                        .multilineTextAlignment(textAlignment)
                }
                item.omer.map({
                    Text($0)
                        .font(.system(size: (lang == .he) ? 16 : 14,
                                      weight: .regular, design: .default))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(textAlignment)
                })
            }
            .padding(.leading)
        }
    }
}


struct HDateRow_Previews: PreviewProvider {
    static var items: [DateItem] = [
        DateItem(id: 1,
                 lang: .en,
                 weekday: 1, dow: "Wed", gregDay: 28, gregMonth: "Apr",
                 hdate: "16 Iyyar", parsha: "Parashat Emor",
                 holidays: [], omer: "Omer: 31st day"),
        DateItem(id: 2,
                 lang: .he,
                 weekday: 1,
                 dow: "חמישי",
                 gregDay: 28,
                 gregMonth:   "מאי",
                 hdate: "ט״ז אייר", parsha: "פרשת אמור",
                 holidays: [], omer: "עומר 31"),
        DateItem(id: 3,
                 lang: .en,
                 weekday: 2, dow: "Mon", gregDay: 25, gregMonth: "Sep",
                 hdate: "28 Elul", parsha: "Vayeilech",
                 holidays: ["Shabbat Shuva"]),
    ]

    static var previews: some View {
        Group {
            HDateRow(item: items[0])
            HDateRow(item: items[1])
        }
        .previewLayout(.fixed(width: 300, height: 70))
    }
}
