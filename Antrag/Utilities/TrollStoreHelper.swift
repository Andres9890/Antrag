import Foundation
import UIKit

enum TrollStoreHelper {
    static var isInstalled: Bool {
        // Check typical TrollStore directories or environment variables
        if FileManager.default.fileExists(atPath: "/var/mobile/Library/TrollStore") {
            return true
        }
        if ProcessInfo.processInfo.environment["TROLLSTORE"] != nil {
            return true
        }
        // TrollStore apps are usually installed inside this directory
        if Bundle.main.bundlePath.contains("TrollStore") {
            return true
        }
        return false
    }

    static func openTrollStore() {
        guard let url = URL(string: "trollstore://") else { return }
        UIApplication.shared.open(url)
    }
}
