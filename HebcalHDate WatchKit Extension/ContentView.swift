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
    @EnvironmentObject var modelData: ModelData

    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: HDateList()) {
                    TodayView(item: modelData.dateItems[0])
                }
                NavigationLink(destination: SettingsView()) {
                    Label("Settings", systemImage: "gear")
                }
            }
            .navigationTitle("Hebcal")
        }
        .onChange(of: scenePhase) { (phase) in
            switch phase {
            case .inactive:
                logger.debug("Scene became inactive.")
            case .active:
                logger.debug("Scene became active.")
                modelData.updateDateItems()
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
