//
//  HDateList.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 9/5/21.
//

import Foundation
import SwiftUI
import os

struct HDateList: View {
    @EnvironmentObject var modelData: ModelData
    let logger = Logger(subsystem: "com.hebcal.HebcalHDate.watchkitapp.watchkitextension.HDateList", category: "HDateList")
    @Environment(\.scenePhase) private var scenePhase

    // Lay out the view's body.
    var body: some View {
        List($modelData.dateItems) { item in
            HDateRow(item: item.wrappedValue)
        }
        .navigationTitle("Hebcal")
        .onChange(of: scenePhase) { (phase) in
            if phase == .active {
                logger.debug("Scene became active.")
                modelData.updateDateItems()
            }
        }
    }
}

struct HDateList_Previews: PreviewProvider {
    static var previews: some View {
        HDateList()
            .environmentObject(ModelData.shared)
    }
}
