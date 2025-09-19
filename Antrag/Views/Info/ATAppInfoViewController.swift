//
//  ATAppInfoViewController.swift
//  Antrag - TrollStore Version
//
//  Updated to use TSAppInfo instead of AppInfo from idevice
//

import UIKit

// MARK: - Class extension: ContentStruct
extension ATAppInfoViewController {
	struct LabeledInfo {
		let title: String
		let value: String
	}
}

// MARK: - Class
class ATAppInfoViewController: UITableViewController {
	var appIcon: UIImage? = nil
	private var _infoSections: [[LabeledInfo]] = []
	
	lazy var fadingImageView: UIImageView = {
		let size: CGFloat = 34
		
		let imageView = UIImageView()
		imageView.translatesAutoresizingMaskIntoConstraints = false
		imageView.alpha = 0
		imageView.isHidden = true
		imageView.layer.cornerRadius = size * 0.2337
		imageView.layer.cornerCurve = .continuous
		imageView.clipsToBounds = true
		imageView.layer.borderWidth = 1.0
		imageView.layer.borderColor = UIColor.gray.withAlphaComponent(0.3).cgColor
		
		imageView.widthAnchor.constraint(equalToConstant: 34).isActive = true
		imageView.heightAnchor.constraint(equalToConstant: 34).isActive = true
		return imageView
	}()
	
	let openButton: UIButton = {
		let button = ATOpenButton(type: .system)
		button.alpha = 0
		button.isHidden = true
		return button
	}()
	
	var app: TSAppInfo
	
	init(app: TSAppInfo) {
		self.app = app
		super.init(style: .insetGrouped)
		buildInfoSections()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		setupNavigation()
		setupTableView()
	}
	
	// MARK: Setup
	
	func setupNavigation() {
		Task { [weak self] in
			guard let self else { return }
			if let image = try? await TrollStoreAppManager.getAppIcon(for: app.bundleIdentifier) {
				DispatchQueue.main.async {
					self.appIcon = image
					self.fadingImageView.image = image
					self.navigationItem.titleView = self.fadingImageView
				}
			}
		}
		
		let dismissButton = UIBarButtonItem(systemImageName: "chevron.backward.circle.fill", target: self, action: #selector(dismissAction))
		navigationItem.leftBarButtonItem = dismissButton
		
		openButton.addTarget(self, action: #selector(openButtonTapped), for: .touchUpInside)
		
		let barButtonItem = UIBarButtonItem(customView: openButton)
		navigationItem.rightBarButtonItem = barButtonItem
	}
	
	func setupTableView() {
		let header = ATAppInfoHeaderView()
		header.configure(with: app)
		
		let headerHeight: CGFloat = 120
		header.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: headerHeight)
		
		tableView.tableHeaderView = header
		tableView.separatorInset = .init(top: 0, left: 16, bottom: 0, right: 16)
	}
	
	func buildInfoSections() {
		var general: [LabeledInfo] = []
		var platform: [LabeledInfo] = []
		var signed: [LabeledInfo] = []
		var extra: [LabeledInfo] = []
		var dicts: [LabeledInfo] = []
		var paths: [LabeledInfo] = []
		
		// general
		if let name = app.executableName, !name.isEmpty {
			general.append(.init(title: .localized("Name"), value: name))
		}
		if !app.bundleIdentifier.isEmpty {
			general.append(.init(title: .localized("Bundle Identifier"), value: app.bundleIdentifier))
		}
		if !app.applicationType.isEmpty {
			general.append(.init(title: .localized("Type"), value: app.applicationType))
		}
		
		// platform
		if let version = app.shortVersionString, !version.isEmpty {
			platform.append(.init(title: .localized("Application Version"), value: version))
		}
		if let build = app.bundleVersion, !build.isEmpty {
			platform.append(.init(title: .localized("Application Build"), value: build))
		}
		if let sdk = app.sdkVersion, !sdk.isEmpty {
			platform.append(.init(title: .localized("SDK Version Built with"), value: sdk))
		}
		if let minOS = app.minimumOSVersion, !minOS.isEmpty {
			platform.append(.init(title: .localized("Minimum iOS Version Required"), value: minOS))
		}
		
		// signed
		if let signedby = app.signerIdentity, !signedby.isEmpty {
			signed.append(.init(title: .localized("Signed by"), value: signedby))
		}
		
		// extra
		extra.append(.init(title: .localized("Is an App Clip"), value: app.isAppClip.description))
		extra.append(.init(title: .localized("Can be upgraded"), value: app.isUpgradeable.description))
		
		// dicts
		if let entitlements = app.entitlements, !entitlements.isEmpty {
			dicts.append(.init(title: .localized("Entitlements"), value: ""))
		}
		
		// paths
		if let bundlePath = app.bundlePath, !bundlePath.isEmpty {
			paths.append(.init(title: .localized("Bundle Path"), value: bundlePath))
		}
		if let containerPath = app.containerPath, !containerPath.isEmpty {
			paths.append(.init(title: .localized("Container Path"), value: containerPath))
		}
		
		[general, platform, signed, extra, dicts, paths].forEach {
			if !$0.isEmpty { _infoSections.append($0) }
		}
	}
	
	// MARK: Actions
	
	@objc private func dismissAction() {
		dismiss(animated: true)
	}
	
	@objc private func openButtonTapped() {
		_ = TrollStoreAppManager.openApp(bundleIdentifier: app.bundleIdentifier)
	}
}

// MARK: - Class extension: TableView
extension ATAppInfoViewController {
	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		let offsetY = scrollView.contentOffset.y
		let fadeStart: CGFloat = 0
		let fadeEnd: CGFloat = 100
		
		let targetAlpha: CGFloat
		if offsetY <= fadeStart {
			targetAlpha = 0
		} else if offsetY >= fadeEnd {
			targetAlpha = 1
		} else {
			targetAlpha = (offsetY - fadeStart) / (fadeEnd - fadeStart)
		}
		
		if targetAlpha == 0 {
			if !fadingImageView.isHidden {
				self.fadingImageView.alpha = 0
				self.fadingImageView.isHidden = true
			}
			
			if !openButton.isHidden {
				self.openButton.alpha = 0
				self.openButton.isHidden = true
			}
		} else {
			if fadingImageView.isHidden {
				fadingImageView.alpha = 0
				fadingImageView.isHidden = false
			}
			
			if openButton.isHidden {
				openButton.alpha = 0
				openButton.isHidden = false
			}
			
			self.fadingImageView.alpha = targetAlpha
			self.openButton.alpha = targetAlpha
		}
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		_infoSections.count
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		_infoSections[section].count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = UITableViewCell()
		let item = _infoSections[indexPath.section][indexPath.row]
		
		var config = UIListContentConfiguration.valueCell()
		config.text = item.title
		config.secondaryText = item.value
		config.secondaryTextProperties.color = .secondaryLabel
		cell.contentConfiguration = config
		
		let selectableTitles: [String] = [
			.localized("Entitlements")
		]
		
		if selectableTitles.contains(item.title) {
			cell.selectionStyle = .default
			cell.accessoryType = .disclosureIndicator
		} else {
			cell.selectionStyle = .none
			cell.accessoryType = .none
		}
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let item = _infoSections[indexPath.section][indexPath.row]
		
		if item.title == .localized("Entitlements") {
			let entitlements = app.entitlements ?? [:]
			let convertedEntitlements = entitlements.mapValues { AnyCodable($0) }
			let detailVC = ATDictionaryViewController(title: item.title, entitlements: convertedEntitlements)
			navigationController?.pushViewController(detailVC, animated: true)
		}
	}
	
	override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		let item = _infoSections[indexPath.section][indexPath.row]
		
		return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
			let copyAction = UIAction(title: .localized("Copy"), image: UIImage(systemName: "doc.on.doc")) { _ in
				UIPasteboard.general.string = item.value
			}
			return UIMenu(children: [copyAction])
		}
	}
}

// MARK: - AnyCodable Helper
struct AnyCodable: Codable {
	let value: Any
	
	init(_ value: Any) {
		self.value = value
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		
		if container.decodeNil() {
			value = NSNull()
		} else if let bool = try? container.decode(Bool.self) {
			value = bool
		} else if let int = try? container.decode(Int.self) {
			value = int
		} else if let double = try? container.decode(Double.self) {
			value = double
		} else if let string = try? container.decode(String.self) {
			value = string
		} else if let array = try? container.decode([AnyCodable].self) {
			value = array.map { $0.value }
		} else if let dictionary = try? container.decode([String: AnyCodable].self) {
			value = dictionary.mapValues { $0.value }
		} else {
			throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
		}
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		
		switch value {
		case is NSNull:
			try container.encodeNil()
		case let bool as Bool:
			try container.encode(bool)
		case let int as Int:
			try container.encode(int)
		case let double as Double:
			try container.encode(double)
		case let string as String:
			try container.encode(string)
		case let array as [Any]:
			try container.encode(array.map { AnyCodable($0) })
		case let dictionary as [String: Any]:
			try container.encode(dictionary.mapValues { AnyCodable($0) })
		default:
			throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Unsupported type"))
		}
	}
}