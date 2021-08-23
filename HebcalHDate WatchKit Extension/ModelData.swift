//
//  ModelData.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 8/23/21.
//

import Foundation
import Combine
import ClockKit
import WatchKit
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

    // Use this value to determine whether you have changes that can be saved to disk.
    private var savedIl = Bool()
    private var savedLocale = String()

    // A background queue used to save and load the model data.
    private var background = DispatchQueue(label: "Background Queue",
    qos: .userInitiated)

    // MARK: - Private Methods
    
    // The model's initializer. Do not call this method.
    // Use the shared instance instead.
    private init() {
        // Begin loading the data from disk.
        load()
    }
    
    // Begin saving the drink data to disk.
    private func save() {
        
        // Don't save the data if there haven't been any changes.
        if il == savedIl && locale == savedLocale {
            logger.debug("The settings haven't changed. No need to save.")
            return
        }
        
        // Save as a binary plist file.
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        
        let data: Data
        do {
            // Encode the currentDrinks array.
            data = try encoder.encode(il)
        } catch {
            logger.error("An error occurred while encoding the data: \(error.localizedDescription)")
            return
        }
        
        // Save the data to disk as a binary plist file.
        let saveAction = { [unowned self] in
            do {
                // Write the data to disk
                try data.write(to: self.getDataURL(), options: [.atomic])
    
                // Update the saved value.
                self.savedIl = il
                self.savedLocale = locale

                self.logger.debug("Saved!")
            } catch {
                self.logger.error("An error occurred while saving the data: \(error.localizedDescription)")
            }
        }
        
        // If the app is running in the background, save synchronously.
        if WKExtension.shared().applicationState == .background {
            logger.debug("Synchronously saving the model on \(Thread.current).")
            saveAction()
        } else {
            // Otherwise save the data on a background queue.
            background.async { [unowned self] in
                logger.debug("Asynchronously saving the model on a background thread.")
                saveAction()
            }
        }
    }
    
    // Begin loading the data from disk.
    private func load() {
        // Read the data from a background queue.
        background.async { [unowned self] in
            logger.debug("Loading the model.")
        
            var il: Bool
            
            do {
                // Load the drink data from a binary plist file.
                let data = try Data(contentsOf: self.getDataURL())
                
                // Decode the data.
                let decoder = PropertyListDecoder()
                il = try decoder.decode(Bool.self, from: data)
                logger.debug("Data loaded from disk")
            } catch CocoaError.fileReadNoSuchFile {
                logger.debug("No file found--creating an empty drink list.")
                il = false
            } catch {
                fatalError("*** An unexpected error occurred while loading the drink list: \(error.localizedDescription) ***")
            }
            
            // Update the entires on the main queue.
            DispatchQueue.main.async { [unowned self] in
                // Update the saved value.
                savedIl = il
                savedLocale = locale
            }
        }
    }
    
    // Returns the URL for the plist file that stores the drink data.
    private func getDataURL() throws -> URL {
        // Get the URL for the app's document directory.
        let fileManager = FileManager.default
        let documentDirectory = try fileManager.url(for: .documentDirectory,
                                                    in: .userDomainMask,
                                                    appropriateFor: nil,
                                                    create: false)
        
        // Append the file name to the directory.
        return documentDirectory.appendingPathComponent("HebcalHDate.plist")
    }
}
