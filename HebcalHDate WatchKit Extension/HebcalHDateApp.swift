//
//  HebcalHDateApp.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 8/17/21.
//

import SwiftUI

@main
struct HebcalHDateApp: App {
    @StateObject var settings = ModelData.shared
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
    }
}
