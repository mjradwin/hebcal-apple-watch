//
//  SettingsView.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 9/6/21.
//

import Foundation
import SwiftUI
import Hebcal

// The app's main view.
struct SettingsView: View {
    @EnvironmentObject var modelData: ModelData

    var langDescription: String {
        switch modelData.lang {
            case TranslationLang.en.rawValue:
                return "e.g. “Sukkot”"
        case TranslationLang.ashkenazi.rawValue:
            return "e.g. “Sukkos”"
        case TranslationLang.he.rawValue:
            return "e.g. \"סוּכּוֹת\""
        default:
            return ""
        }
    }
    var ilDescription: String {
        return (modelData.il ? "Israel" : "Diaspora") + " schedule"
    }

    // Lay out the view's body.
    var body: some View {
        Form {
            Section(header: Text(langDescription).textCase(.none),
                    content: {
                Picker("Language", selection: $modelData.lang) {
                    Text("Sephardic").tag(TranslationLang.en.rawValue)
                    Text("Ashkenazi").tag(TranslationLang.ashkenazi.rawValue)
                    Text("Hebrew").tag(TranslationLang.he.rawValue)
                }
            })
            Section(header: Text(ilDescription).textCase(.none),
                    content: {
                Toggle(isOn: $modelData.il) {
                    Text("Israel")
                }
            })
        }
        .navigationTitle("Settings")
    }
}


// Configure a preview of the coffee tracker view.
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(ModelData.shared)
    }
}
