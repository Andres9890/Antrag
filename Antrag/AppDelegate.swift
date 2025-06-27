//
//  AppDelegate.swift
//  syslog
//
//  Created by samara on 14.05.2025.
//

import UIKit
import IDeviceSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
	let heartbeart = HeartbeatManager.shared
	
        func application(
                _ application: UIApplication,
                didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
        ) -> Bool {
                _createSourcesDirectory()
                if !TrollStoreHelper.isInstalled {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                UIAlertController.showAlertWithOk(
                                        title: "TrollStore Required",
                                        message: "Please install this app through TrollStore."
                                )
                        }
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

