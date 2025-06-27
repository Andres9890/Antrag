import UIKit

protocol InstallationProxyAppsDelegate: AnyObject {
    func updateApplications(with apps: [AppInfo])
}

class InstallationAppProxy {
    weak var delegate: InstallationProxyAppsDelegate?
    private let troll = TrollStoreManager.shared

    func listApps() async throws {
        let apps = troll.installedApps()
        await MainActor.run {
            delegate?.updateApplications(with: apps)
        }
    }

    static func deleteApp(for id: String) async throws {
        TrollStoreManager.shared.uninstall(appId: id)
    }

    private static var iconCache: [String: UIImage] = [:]
    private static let iconCacheQueue = DispatchQueue(label: "iconCacheQueue")

    static func getAppIconCached(for id: String) async throws -> UIImage? {
        if let cached = iconCacheQueue.sync(execute: { iconCache[id] }) {
            return cached
        }
        let image = try await getAppIcon(for: id)
        if let img = image {
            iconCacheQueue.async { iconCache[id] = img }
        }
        return image
    }

    static func getAppIcon(for id: String) async throws -> UIImage? {
        let apps = TrollStoreManager.shared.installedApps()
        guard let app = apps.first(where: { $0.CFBundleIdentifier == id }),
              let path = app.Path else { return nil }

        let icons = app.CFBundleIcons?["CFBundlePrimaryIcon"]?.value as? [String: Any]
        let iconFiles = icons?["CFBundleIconFiles"] as? [String] ?? []
        for file in iconFiles.reversed() {
            let full = URL(fileURLWithPath: path).appendingPathComponent(file).path
            if let image = UIImage(contentsOfFile: full) {
                return image
            }
            if let image = UIImage(contentsOfFile: full + "@2x.png") {
                return image
            }
        }
        return nil
    }
}
