//
//  ContentView.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 8/17/21.
//

import SwiftUI
import os

struct ContentView: View {

    let logger = Logger(subsystem: "com.hebcal.HebcalHDate.watchkitapp.watchkitextension.ContentView", category: "Root View")

    @EnvironmentObject var modelData:ModelData = ModelData.shared

    let hebDateStr = getHebDateString(forDate: Date())
    let parshaStr = getParshaString(date: Date())

    var body: some View {
        NavigationView {
            VStack {
                Text(hebDateStr)
                    .fontWeight(.thin)
                    .multilineTextAlignment(.center)
                    .padding()

                Text(parshaStr)
                    .fontWeight(.thin)
                    .multilineTextAlignment(.center)
                    .padding()

                Toggle(isOn: $modelData.il) {
                    Text("Israel")
                }
            }
            .navigationTitle("Hebcal")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
