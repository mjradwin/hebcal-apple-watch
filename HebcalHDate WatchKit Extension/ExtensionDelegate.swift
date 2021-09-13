//
//  ExtensionDelegate.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 9/12/21.
//

import Foundation
import WatchKit
import os

// The app's extension delegate.
class ExtensionDelegate: NSObject, WKExtensionDelegate {
    let logger = Logger(subsystem: "com.hebcal.HebcalHDate.watchkitapp.watchkitextension.ExtensionDelegate",
                        category: "Extension Delegate")

    // MARK: - Delegate Methods

    // Called when a background task occurs.
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        logger.debug("Handling a background task...")
        logger.debug("App State: \(WKExtension.shared().applicationState.rawValue)")
        for task in backgroundTasks {
            logger.debug("Task: \(task)")
            switch task {
            // Handle background refresh tasks.
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                let model = ModelData.shared
                model.updateDateItems()
                // Mark the task as ended, and request an updated snapshot, if necessary.
                backgroundTask.setTaskCompletedWithSnapshot(true)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}

// Schedule the next background refresh task.

let scheduleLogger = Logger(
    subsystem: "com.hebcal.HebcalHDate.watchkitapp.watchkitextension.scheduleLogger",
    category: "Scheduler")

func scheduleBackgroundRefreshTasks() {
    scheduleLogger.debug("Scheduling a background task.")

    // Get the shared extension object.
    let watchExtension = WKExtension.shared()

    // We want 8 app updates a day, so schedule refresh 3 hours in the future
    let targetDate = Date().addingTimeInterval(3.0 * 60.0 * 60.0)
    // let targetDate = Date().addingTimeInterval(1.0)

    // Schedule the background refresh task.
    watchExtension.scheduleBackgroundRefresh(withPreferredDate: targetDate, userInfo: nil) { (error) in

        // Check for errors.
        if let error = error {
            scheduleLogger.error("An error occurred while scheduling a background refresh task: \(error.localizedDescription)")
            return
        }

        scheduleLogger.debug("Task scheduled!")
    }
}
