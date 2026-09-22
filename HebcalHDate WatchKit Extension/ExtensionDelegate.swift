//
//  ExtensionDelegate.swift
//  HebcalHDate WatchKit Extension
//
//  Created by Michael Radwin on 9/12/21.
//

import Foundation
import WatchKit
import ClockKit
import os

// Bundle identifier of the widget extension that hosts the migrated widgets.
private let widgetExtensionBundleIdentifier = "com.hebcal.HebcalHDate.watchkitapp.widgets"

// The app's extension delegate.
class ExtensionDelegate: NSObject, WKApplicationDelegate {
    let logger = Logger(subsystem: "com.hebcal.HebcalHDate.watchkitapp.watchkitextension.ExtensionDelegate",
                        category: "Extension Delegate")

    // MARK: - Delegate Methods

    // Called when a background task occurs.
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        logger.debug("Handling a background task...")
        logger.debug("App State: \(WKApplication.shared().applicationState.rawValue)")
        for task in backgroundTasks {
            logger.debug("Task: \(task)")
            switch task {
            // Handle background refresh tasks.
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                let model = ModelData.shared
                model.checkTimeZone()
                model.updateDateItems()
                // Schedule the next background update.
                scheduleBackgroundRefreshTasks()
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

// MARK: - ClockKit -> WidgetKit complication migration
//
// watchOS calls this migrator once, when a user updates in place from a build
// that still had ClockKit complications on a watch face to a build that provides
// this conformance. The legacy CLKComplicationDescriptor identifiers were reused
// verbatim as the WidgetKit `kind` strings (see HebcalWidgetBundle), so each old
// complication maps 1:1 to its equivalent static widget.
//
// Note: this is a one-shot, in-place-upgrade event. Users who already updated to
// a WidgetKit build that lacked this migrator have missed the window and must
// re-add complications by hand; only users still on the old ClockKit version
// benefit from this on their next update.
extension ExtensionDelegate: CLKComplicationWidgetMigrator {
    func widgetConfiguration(
        from complicationDescriptor: CLKComplicationDescriptor
    ) async -> CLKComplicationWidgetMigrationConfiguration? {
        CLKComplicationStaticWidgetMigrationConfiguration(
            kind: complicationDescriptor.identifier,
            extensionBundleIdentifier: widgetExtensionBundleIdentifier
        )
    }
}

// Schedule the next background refresh task.

let scheduleLogger = Logger(
    subsystem: "com.hebcal.HebcalHDate.watchkitapp.watchkitextension.scheduleLogger",
    category: "Scheduler")

private let backgroundRefreshInterval = 2.0 * 60.0 * 60.0
func scheduleBackgroundRefreshTasks() {
    let refreshTime = Date().advanced(by: backgroundRefreshInterval)
    WKApplication.shared().scheduleBackgroundRefresh(
        withPreferredDate: refreshTime,
        userInfo: nil
    ) { (error) in
        scheduleLogger.debug("Scheduled the next background refresh task.")
    }
}
