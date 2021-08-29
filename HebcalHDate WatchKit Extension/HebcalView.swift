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
struct HebcalView: View {

    @EnvironmentObject var modelData: ModelData

    // Lay out the view's body.
    var body: some View {
        NavigationView {
            VStack {
                Text(modelData.currentHebDateStr)
                    .fontWeight(.regular)
                    .multilineTextAlignment(.center)
                    .padding()
                HStack {
                    Image("torah-orange-solid-2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22.0, height: 22.0)
                    Text(modelData.currentParshaStr)
                        .fontWeight(.thin)
                        .multilineTextAlignment(.center)
                }
                Spacer()
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
