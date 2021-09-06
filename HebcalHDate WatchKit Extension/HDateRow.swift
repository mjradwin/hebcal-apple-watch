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
    @EnvironmentObject var modelData: ModelData

    var item: DateItem
    var lang: TranslationLang  {
        TranslationLang(rawValue: modelData.lang) ?? TranslationLang.en
    }

    var body: some View {
        HStack {
            VStack {
                Text(item.dow)
                    .font(.system(size: 10, weight: .semibold, design: .default))
                    .foregroundColor(.gray)
                Text(String(item.gregDay))
                    .font(.system(size: 20, weight: .semibold, design: .default))
                    .foregroundColor(.orange)
                Text(item.gregMonth)
                    .font(.system(size: 12, weight: .regular, design: .default))
            }
            .padding(.leading, 5.0)
            if lang == .he {
                Spacer()
            }
            VStack(alignment: (lang == .he) ? .trailing : .leading) {
                Text(item.hdate)
                    .font(.system(size: 16, weight: .regular, design: .default))
                Text(item.parsha)
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(.gray)
                item.holiday.map({
                    Text($0)
                        .font(.system(size: 12, weight: .light, design: .default))
                        .foregroundColor(.yellow)
                })
            }
            .padding(.leading)
        }
    }
}


struct HDateRow_Previews: PreviewProvider {
    static var items: [DateItem] = [
        DateItem(dow: "Sun", gregDay: 4, gregMonth: "Sep", hdate: "27 Elul", parsha: "Nitzavim"),
        DateItem(dow: "Mon", gregDay: 25, gregMonth: "Sep", hdate: "28 Elul", parsha: "Vayeilech",
                 holiday: "Shabbat Shuva"),
    ]

    static var previews: some View {
        Group {
            HDateRow(item: items[0])
            HDateRow(item: items[1])
        }
        .previewLayout(.fixed(width: 300, height: 70))
    }
}
