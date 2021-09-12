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
                return "e.g. Shabbat Shuvah"
        case TranslationLang.ashkenazi.rawValue:
            return "e.g. Shabbos Shuvah"
        case TranslationLang.he.rawValue:
            return "e.g. שַׁבָּת שׁוּבָה"
        default:
            return ""
        }
    }

    // Lay out the view's body.
    var body: some View {
        NavigationView {
            Form {
                Picker("Language", selection: $modelData.lang) {
                    Text("Sephardic").tag(TranslationLang.en.rawValue)
                    Text("Ashkenazi").tag(TranslationLang.ashkenazi.rawValue)
                    Text("Hebrew").tag(TranslationLang.he.rawValue)
                }
            }
            Text(langDescription)
                .font(.system(size: 14, weight: .thin, design: .default))
                .italic()
                .multilineTextAlignment(.center)
                .padding([.leading, .trailing, .bottom])
            Form {
                Toggle(isOn: $modelData.il) {
                    Text("Israel")
                }
            }
            Text(modelData.il ?
                    "Israel holiday and Torah reading schedule" :
                    "Diaspora holiday and Torah reading schedule")
                .font(.system(size: 14, weight: .thin, design: .default))
                .multilineTextAlignment(.center)
                .padding(.leading)
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
