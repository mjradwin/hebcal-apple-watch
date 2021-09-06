//
//  HebcalView.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 8/23/21.
//

import Foundation
import SwiftUI

// The app's main view.
struct HebcalView: View {

    @EnvironmentObject var modelData: ModelData

    // Lay out the view's body.
    var body: some View {
        NavigationView {
            TabView {
                HDateList()
                    .tabItem { Label("Hebcal", systemImage: "list.dash") }
                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gear") }
            }
            .navigationTitle("Hebcal")
        }
    }
}


// Configure a preview of the coffee tracker view.
struct HebcalView_Previews: PreviewProvider {
    static var previews: some View {
        HebcalView()
            .environmentObject(ModelData.shared)
    }
}
