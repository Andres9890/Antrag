//
//  AppDelegate.swift
//  syslog
//
//  Created by samara on 14.05.2025.
//

import UIKit
import IDeviceSwift

// TrollStore integration
import Foundation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
	let heartbeart = HeartbeatManager.shared
	
        func application(
                _ application: UIApplication,
                didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
        ) -> Bool {
                _createSourcesDirectory()

                // Verify TrollStore installation
                if !Bundle.main.isInstalledViaTrollStore {
                        UIAlertController.showAlertWithOk(
                                title: "TrollStore Required",
                                message: "This app must be installed via TrollStore to function correctly."
                        )
                }
                return true
        }
	
	private func _createSourcesDirectory() {
		let fileManager = FileManager.default
		
		let directories: [URL] = [
			URL.documentsDirectory.appending(component: "keep")
		]
		
		for url in directories {
			try? fileManager.createDirectoryIfNeeded(at: url)
		}
	}
}

