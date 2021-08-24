//
//  ContentView.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 8/17/21.
//

import SwiftUI
import os
import Hebcal

struct ContentView: View {
    let logger = Logger(subsystem: "com.hebcal.HebcalHDate.watchkitapp.watchkitextension.ContentView", category: "Root View")

    @StateObject var settings = ModelData.shared

    let hebDateStr = getHebDateString(forDate: Date())
    let parshaStr = getParshaString(date: Date(), il: false, lang: TranslationLang.en)

    var body: some View {
        NavigationView {
            VStack {
                Text(hebDateStr)
                    .fontWeight(.regular)
                    .multilineTextAlignment(.center)
                    .padding()
                HStack {
                    Image("torah-orange-png")
                    Text(parshaStr)
                        .fontWeight(.thin)
                        .multilineTextAlignment(.center)
                }
                Form {
                    Picker("Language", selection: $settings.lang) {
                        Text("Sephardic").tag(TranslationLang.en.rawValue)
                        Text("Ashkenazi").tag(TranslationLang.ashkenazi.rawValue)
                        Text("Hebrew").tag(TranslationLang.he.rawValue)
                    }
                    Toggle(isOn: $settings.il) {
                        Text("Israel")
                    }
                }
            }
            .navigationTitle("Hebcal")
        }
        .environmentObject(settings)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
