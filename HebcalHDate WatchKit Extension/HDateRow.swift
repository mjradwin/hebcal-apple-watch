//
//  HDateRow.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 9/5/21.
//

import Foundation
import SwiftUI

struct HDateRow: View {
    var item: DateItem

    var body: some View {
        HStack {
            VStack {
                Text(String(item.gregDay))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                Text(item.gregMonth)
                    .font(.system(size: 14, weight: .semibold, design: .default))
            }
            .padding()
            VStack(alignment: .leading) {
                Text(item.hdate)
                    .font(.system(size: 16, weight: .regular, design: .default))
                Text(item.parsha)
                    .font(.system(size: 14, weight: .light, design: .default))
                item.holiday.map({
                    Text($0)
                        .font(.system(size: 12, weight: .light, design: .default))
                })
            }
            .padding(.leading)
        }
    }
}


struct HDateRow_Previews: PreviewProvider {
    static var items: [DateItem] = [
        DateItem(gregDay: 4, gregMonth: "Sep", hdate: "27 Elul", parsha: "Nitzavim"),
        DateItem(gregDay: 25, gregMonth: "Sep", hdate: "28 Elul", parsha: "Vayeilech",
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
