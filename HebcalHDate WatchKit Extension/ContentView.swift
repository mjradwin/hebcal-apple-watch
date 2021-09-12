//
//  ContentView.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 8/17/21.
//

import SwiftUI

struct ContentView: View {
    @StateObject var settings = ModelData.shared

    var body: some View {
        TabView {
            HDateList()
                .tabItem { Label("Hebcal", systemImage: "list.dash") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .navigationTitle("Hebcal")
        .environmentObject(settings)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ModelData.shared)
    }
}
