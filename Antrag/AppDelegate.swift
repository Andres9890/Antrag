//
//  AppDelegate.swift
//  Antrag - TrollStore Version
//
//  Removed idevice and HeartbeatManager dependencies
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
	) -> Bool {
		_createDirectories()
		_validateTrollStoreEnvironment()
		return true
	}
	
	private func _createDirectories() {
		let fileManager = FileManager.default
		
		let directories: [URL] = [
			URL.documentsDirectory.appending(component: "keep")
		]
		
		for url in directories {
			try? fileManager.createDirectoryIfNeeded(at: url)
		}
	}
	
	private func _validateTrollStoreEnvironment() {
		// Verify that we have access to LSApplicationWorkspace
		// This will only work if the app is installed via TrollStore
		guard NSClassFromString("LSApplicationWorkspace") != nil else {
			print("⚠️ Warning: LSApplicationWorkspace not available. Make sure this app is installed via TrollStore.")
			return
		}
		
		print("TrollStore environment detected - LSApplicationWorkspace available")
	}
}