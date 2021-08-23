//
//  ModelData.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 8/23/21.
//

import Foundation
import ClockKit
import os

class ModelData: ObservableObject {
    let logger = Logger(subsystem: "com.hebcal.HebcalHDate.watchkitapp.watchkitextension.ModelData", category: "Root View")

    // The data model needs to be accessed both from the app extension
    // and from the complication controller.
    static let shared = ModelData()

    @Published public var il = Bool() {
        didSet {
            logger.debug("A value has been assigned to the Israel property.")
            // Update any complications on active watch faces.
            let server = CLKComplicationServer.sharedInstance()
            for complication in server.activeComplications ?? [] {
                server.reloadTimeline(for: complication)
            }
            // Begin saving the data.
            self.save()
        }
    }
    @Published public var locale = String() {
        didSet {
            logger.debug("A value has been assigned to the Locale property.")
            // Update any complications on active watch faces.
            let server = CLKComplicationServer.sharedInstance()
            for complication in server.activeComplications ?? [] {
                server.reloadTimeline(for: complication)
            }
            // Begin saving the data.
            self.save()
        }
    }

    let defaults = UserDefaults.standard

    // MARK: - Private Methods
    
    // The model's initializer. Do not call this method.
    // Use the shared instance instead.
    private init() {
        // Begin loading the data from disk.
        load()
    }
    
    // Begin saving the drink data to disk.
    private func save() {
        logger.debug("Saving defaults")
        defaults.set(il, forKey: "israel")
        defaults.set(locale, forKey: "locale")
    }
    
    // Begin loading the data from disk.
    private func load() {
        logger.debug("Loading defaults")
        il = defaults.bool(forKey: "israel")
        locale = defaults.string(forKey: "locale") ?? "en"
    }
}
