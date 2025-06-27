import Foundation
import UIKit

@objc class TrollStoreManager: NSObject {
    static let shared = TrollStoreManager()
    private let applicationsPath = "/var/containers/Bundle/TrollStore/Applications"

    func installedApps() -> [IDeviceSwift.AppInfo] {
        var apps: [IDeviceSwift.AppInfo] = []
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: applicationsPath) else { return [] }
        for item in contents where item.hasSuffix(".app") {
            let appPath = (applicationsPath as NSString).appendingPathComponent(item)
            let infoPath = (appPath as NSString).appendingPathComponent("Info.plist")
            if let data = FileManager.default.contents(atPath: infoPath),
               let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
                let info = IDeviceSwift.AppInfo(dictionary: plist)
                apps.append(info)
            }
        }
        return apps
    }

    func uninstall(appId: String) {
        _ = TSApplicationsManager.shared()?.uninstallApp(appId)
    }

    func open(appId: String) {
        _ = TSApplicationsManager.shared()?.openApplication(withBundleID: appId)
    }
}
