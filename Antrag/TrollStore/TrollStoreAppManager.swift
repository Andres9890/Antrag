//
//  TrollStoreAppManager.swift
//  Antrag
//
//  TrollStore-based app management replacing idevice
//

import Foundation
import UIKit

// MARK: - App Info Model
struct TSAppInfo {
    let bundleIdentifier: String
    let displayName: String?
    let executableName: String?
    let bundleVersion: String?
    let shortVersionString: String?
    let applicationType: String
    let bundlePath: String?
    let containerPath: String?
    let signerIdentity: String?
    let entitlements: [String: Any]?
    let isAppClip: Bool
    let isUpgradeable: Bool
    let minimumOSVersion: String?
    let sdkVersion: String?
    let iconData: Data?
    
    init(from proxy: LSApplicationProxy) {
        self.bundleIdentifier = proxy.bundleIdentifier ?? ""
        self.displayName = proxy.localizedName
        self.executableName = proxy.bundleExecutable
        self.bundleVersion = proxy.bundleVersion
        self.shortVersionString = proxy.shortVersionString
        self.applicationType = proxy.applicationType ?? "Unknown"
        self.bundlePath = proxy.bundleURL?.path
        self.containerPath = proxy.containerURL?.path
        self.signerIdentity = proxy.signerIdentity
        self.entitlements = proxy.entitlements
        self.isAppClip = proxy.isAppClip
        self.isUpgradeable = !proxy.isLaunchProhibited // Approximation
        
        // Extract additional info from Info.plist
        let infoPlist = proxy.infoPlist ?? [:]
        self.minimumOSVersion = infoPlist["MinimumOSVersion"] as? String
        self.sdkVersion = infoPlist["DTPlatformVersion"] as? String
        
        // Get icon data
        self.iconData = Self.extractIconData(from: proxy)
    }
    
    private static func extractIconData(from proxy: LSApplicationProxy) -> Data? {
        // Try different icon variants
        let variants = ["AppIcon60x60", "AppIcon", "icon"]
        
        for variant in variants {
            if let iconData = proxy.iconData(forVariant: variant) {
                return iconData
            }
        }
        
        // Fallback: try to read icon from bundle
        guard let bundleURL = proxy.bundleURL else { return nil }
        
        do {
            let infoPlistURL = bundleURL.appendingPathComponent("Info.plist")
            let plistData = try Data(contentsOf: infoPlistURL)
            let plist = try PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any]
            
            // Extract icon file names
            var iconNames: [String] = []
            
            if let icons = plist?["CFBundleIcons"] as? [String: Any],
               let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
               let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String] {
                iconNames.append(contentsOf: iconFiles)
            }
            
            if let iconFile = plist?["CFBundleIconFile"] as? String {
                iconNames.append(iconFile)
            }
            
            // Try to find the icon file
            for iconName in iconNames {
                let extensions = ["", ".png", "@2x.png", "@3x.png"]
                for ext in extensions {
                    let iconURL = bundleURL.appendingPathComponent(iconName + ext)
                    if let iconData = try? Data(contentsOf: iconURL) {
                        return iconData
                    }
                }
            }
        } catch {
            print("Failed to extract icon: \(error)")
        }
        
        return nil
    }
}

// MARK: - Delegate Protocol
protocol TrollStoreAppManagerDelegate: AnyObject {
    func didUpdateApplications(_ apps: [TSAppInfo])
    func didFailWithError(_ error: Error)
}

// MARK: - TrollStore App Manager
class TrollStoreAppManager: NSObject {
    weak var delegate: TrollStoreAppManagerDelegate?
    
    private var workspace: LSApplicationWorkspace? {
        guard let workspaceClass = NSClassFromString("LSApplicationWorkspace") as? NSObject.Type else {
            return nil
        }
        
        return workspaceClass.perform(NSSelectorFromString("defaultWorkspace"))?.takeUnretainedValue() as? LSApplicationWorkspace
    }
    
    // MARK: - App Enumeration
    
    func listAllApplications() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.performAppListing()
        }
    }
    
    private func performAppListing() {
        guard let workspace = workspace else {
            DispatchQueue.main.async {
                self.delegate?.didFailWithError(TSError.workspaceNotAvailable)
            }
            return
        }
        
        do {
            let allApps = workspace.allApplications()
            let appInfos = allApps.compactMap { proxy in
                TSAppInfo(from: proxy)
            }
            
            DispatchQueue.main.async {
                self.delegate?.didUpdateApplications(appInfos)
            }
        } catch {
            DispatchQueue.main.async {
                self.delegate?.didFailWithError(error)
            }
        }
    }
    
    // MARK: - App Management
    
    static func openApp(bundleIdentifier: String) -> Bool {
        guard let workspaceClass = NSClassFromString("LSApplicationWorkspace") as? NSObject.Type,
              let workspace = workspaceClass.perform(NSSelectorFromString("defaultWorkspace"))?.takeUnretainedValue() else {
            return false
        }
        
        let result = workspace.perform(NSSelectorFromString("openApplicationWithBundleID:"), with: bundleIdentifier)
        return result?.takeUnretainedValue() as? Bool ?? false
    }
    
    static func deleteApp(bundleIdentifier: String) throws {
        guard let workspaceClass = NSClassFromString("LSApplicationWorkspace") as? NSObject.Type,
              let workspace = workspaceClass.perform(NSSelectorFromString("defaultWorkspace"))?.takeUnretainedValue() else {
            throw TSError.workspaceNotAvailable
        }
        
        let options: [String: Any] = [:]
        let result = workspace.perform(
            NSSelectorFromString("uninstallApplication:withOptions:"),
            with: bundleIdentifier,
            with: options
        )
        
        if !(result?.takeUnretainedValue() as? Bool ?? false) {
            throw TSError.uninstallFailed
        }
    }
    
    // MARK: - Icon Caching
    
    private static var iconCache: [String: UIImage] = [:]
    
    static func getAppIcon(for bundleIdentifier: String) async throws -> UIImage? {
        if let cachedIcon = iconCache[bundleIdentifier] {
            return cachedIcon
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let workspaceClass = NSClassFromString("LSApplicationWorkspace") as? NSObject.Type,
                      let workspace = workspaceClass.perform(NSSelectorFromString("defaultWorkspace"))?.takeUnretainedValue() as? LSApplicationWorkspace else {
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let proxy = workspace.applicationProxy(forIdentifier: bundleIdentifier) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let iconData = TSAppInfo.extractIconData(from: proxy)
                
                let image = iconData.flatMap { UIImage(data: $0) }
                
                if let image = image {
                    DispatchQueue.main.async {
                        iconCache[bundleIdentifier] = image
                    }
                }
                
                continuation.resume(returning: image)
            }
        }
    }
}

// MARK: - Error Types
enum TSError: Error, LocalizedError {
    case workspaceNotAvailable
    case uninstallFailed
    case appNotFound
    
    var errorDescription: String? {
        switch self {
        case .workspaceNotAvailable:
            return "LSApplicationWorkspace not available. App must be installed via TrollStore."
        case .uninstallFailed:
            return "Failed to uninstall application."
        case .appNotFound:
            return "Application not found."
        }
    }
}

// MARK: - Objective-C Bridge Types
@objc protocol LSApplicationWorkspace {
    static func defaultWorkspace() -> Self
    func allApplications() -> [LSApplicationProxy]
    func applicationProxy(forIdentifier identifier: String) -> LSApplicationProxy?
    func openApplicationWithBundleID(_ bundleID: String) -> Bool
    func uninstallApplication(_ identifier: String, withOptions options: [String: Any]) -> Bool
}

@objc protocol LSApplicationProxy {
    var bundleIdentifier: String? { get }
    var localizedName: String? { get }
    var bundleExecutable: String? { get }
    var bundleVersion: String? { get }
    var shortVersionString: String? { get }
    var applicationType: String? { get }
    var bundleURL: URL? { get }
    var containerURL: URL? { get }
    var signerIdentity: String? { get }
    var entitlements: [String: Any]? { get }
    var infoPlist: [String: Any]? { get }
    var isAppClip: Bool { get }
    var isLaunchProhibited: Bool { get }
    
    func iconData(forVariant variant: String) -> Data?
}