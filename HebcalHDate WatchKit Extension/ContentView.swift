//
//  ContentView.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 8/17/21.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            TabView {
                HDateList()
                    .tabItem { Label("Hebcal", systemImage: "list.dash") }
                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gear") }
            }
            .tabViewStyle(PageTabViewStyle())
            .navigationTitle("Hebcal")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ModelData.shared)
    }
}
