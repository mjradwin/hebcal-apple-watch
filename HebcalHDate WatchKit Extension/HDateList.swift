//
//  HDateList.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 9/5/21.
//

import Foundation
import SwiftUI

struct HDateList: View {
    @EnvironmentObject var modelData: ModelData

    // Lay out the view's body.
    var body: some View {
        List(modelData.dateItems) {
            HDateRow(item: $0)
                .environmentObject(modelData)
        }
        .navigationTitle("Hebcal")
    }
}

struct HDateList_Previews: PreviewProvider {
    static var previews: some View {
        HDateList()
            .environmentObject(ModelData.shared)
    }
}
