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
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationView {
            TabView {
                HDateList()
                    .tabItem { Label("Hebcal", systemImage: "circle.fill") }
                SettingsView()
                    .tabItem { Label("Settings", systemImage: "circle.fill") }
            }
            .tabViewStyle(PageTabViewStyle())
            .navigationTitle("Hebcal")
        }
        .onChange(of: scenePhase) { (phase) in
            switch phase {
            case .inactive:
                logger.debug("Scene became inactive.")
            case .active:
                logger.debug("Scene became active.")
            case .background:
                logger.debug("Scene moved to the background.")
                // Schedule a background refresh task
                // to update the complications.
                scheduleBackgroundRefreshTasks()
            @unknown default:
                logger.debug("Scene entered unknown state.")
                assertionFailure()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ModelData.shared)
    }
}
