//
//  SettingsView.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 9/6/21.
//

import Foundation

//
//  HebcalView.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 8/23/21.
//

import Foundation
import SwiftUI
import Hebcal

// The app's main view.
struct SettingsView: View {
    @EnvironmentObject var modelData: ModelData

    // Lay out the view's body.
    var body: some View {
        NavigationView {
            Form {
                Picker("Language", selection: $modelData.lang) {
                    Text("Sephardic").tag(TranslationLang.en.rawValue)
                    Text("Ashkenazi").tag(TranslationLang.ashkenazi.rawValue)
                    Text("Hebrew").tag(TranslationLang.he.rawValue)
                }
                Toggle(isOn: $modelData.il) {
                    Text("Israel")
                }
            }
            .navigationTitle("Settings")
        }
    }
}


// Configure a preview of the coffee tracker view.
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(ModelData.shared)
    }
}
