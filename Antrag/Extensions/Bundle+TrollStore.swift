import Foundation

extension Bundle {
    var isInstalledViaTrollStore: Bool {
        let containerURL = URL(fileURLWithPath: bundlePath).deletingLastPathComponent()
        let fm = FileManager.default
        let trollMarker = containerURL.appendingPathComponent("_TrollStore").path
        let liteMarker = containerURL.appendingPathComponent("_TrollStoreLite").path
        return fm.fileExists(atPath: trollMarker) || fm.fileExists(atPath: liteMarker)
    }
}
