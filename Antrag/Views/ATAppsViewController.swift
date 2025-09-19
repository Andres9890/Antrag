//
//  ATAppsViewController.swift
//  Antrag - TrollStore Version
//
//  Updated to use TrollStore's LSApplicationWorkspace instead of idevice
//

import UIKit
import class SwiftUI.UIHostingController

// MARK: Class extension: Enum
extension ATAppsViewController {
	enum AppType: String, CaseIterable, Identifiable {
		case system = "System"
		case user = "User"
		
		var id: String {
			rawValue
		}
		
		var stringValue: String {
			.localized(rawValue)
		}
	}
}

// MARK: - Class
class ATAppsViewController: UITableViewController {
	var apps: [TSAppInfo] = []
	var allSortedApps: [TSAppInfo] = [] // backup
	var sortedApps: [TSAppInfo] = [] // main
	var appType: AppType = .user
	
	private let appManager = TrollStoreAppManager()
	private var _didLoad = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		setupTableView()
		setupNavigation()
		setupSearchController()
		setupAppManager()
		
		// Load apps immediately since we don't need VPN/pairing
		loadApplications()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		// Refresh apps when returning to view
		if _didLoad {
			loadApplications()
		}
	}
	
	// MARK: Setup
	
	func setupNavigation() {
		let segmentedControl = ATSegmentedControl(items: [AppType.system.stringValue, AppType.user.stringValue])
		segmentedControl.selectedSegmentIndex = 1
		segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
		navigationItem.titleView = segmentedControl
		
		let reloadButton = UIBarButtonItem(systemImageName: "arrow.clockwise.circle.fill", target: self, action: #selector(reloadAction))
		navigationItem.leftBarButtonItem = reloadButton
		
		let settingsButton = UIBarButtonItem(systemImageName: "gear.circle.fill", target: self, action: #selector(settingsAction))
		navigationItem.rightBarButtonItem = settingsButton
	}
	
	func setupSearchController() {
		let searchController = UISearchController(searchResultsController: nil)
		searchController.searchResultsUpdater = self
		searchController.obscuresBackgroundDuringPresentation = false
		navigationItem.searchController = searchController
		definesPresentationContext = true
	}
	
	func setupTableView() {
		tableView.separatorStyle = .none
		tableView.register(
			ATAppsTableViewCell.self,
			forCellReuseIdentifier: ATAppsTableViewCell.reuseIdentifier
		)
	}
	
	func setupAppManager() {
		appManager.delegate = self
	}
	
	// MARK: Actions
	
	@objc func segmentChanged(_ sender: UISegmentedControl) {
		appType = sender.selectedSegmentIndex == 0 ? .system : .user
		filterAndReload()
	}
	
	@objc func settingsAction() {
		let nav = UIHostingController(rootView: ATSettingsView())
		nav.modalPresentationStyle = .pageSheet
		
		if let sheet = nav.sheetPresentationController {
			sheet.prefersGrabberVisible = true
		}
		
		present(nav, animated: true)
	}
	
	@objc func reloadAction() {
		loadApplications()
	}
	
	func loadApplications() {
		navigationItem.leftBarButtonItem?.isEnabled = false
		appManager.listAllApplications()
	}
	
	func filterAndReload() {
		let generator = UIImpactFeedbackGenerator(style: .light)
		
		sortedApps = apps
			.filter {
				switch appType {
				case .system: return $0.applicationType == "System"
				case .user: return $0.applicationType == "User"
				}
			}
			.sorted {
				let name1 = $0.displayName ?? $0.executableName ?? ""
				let name2 = $1.displayName ?? $1.executableName ?? ""
				let result = name1.localizedCaseInsensitiveCompare(name2)
				return result == .orderedAscending
			}
		
		allSortedApps = sortedApps
		
		generator.impactOccurred()
		
		if #available(iOS 17.0, *) {
			setNeedsUpdateContentUnavailableConfiguration()
		}
		
		tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
	}
}

// MARK: - TrollStore App Manager Delegate
extension ATAppsViewController: TrollStoreAppManagerDelegate {
	func didUpdateApplications(_ apps: [TSAppInfo]) {
		self.apps = apps
		self._didLoad = true
		self.navigationItem.leftBarButtonItem?.isEnabled = true
		filterAndReload()
	}
	
	func didFailWithError(_ error: Error) {
		self.navigationItem.leftBarButtonItem?.isEnabled = true
		
		UIAlertController.showAlertWithOk(
			title: "Error",
			message: error.localizedDescription
		)
	}
}

// MARK: - Class extension: TableView
extension ATAppsViewController {
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		80
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		sortedApps.count
	}
	
	override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.clipsToBounds = false
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: ATAppsTableViewCell.reuseIdentifier,
			for: indexPath
		) as? ATAppsTableViewCell else {
			return UITableViewCell()
		}
		
		let app = sortedApps[indexPath.row]
		cell.configure(with: app)
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let app = sortedApps[indexPath.row]
		
		tableView.deselectRow(at: indexPath, animated: true)
		
		let detailNavigationController = UINavigationController(rootViewController: ATAppInfoViewController(app: app))
		if #available(iOS 18.0, *) {
			detailNavigationController.preferredTransition = .zoom(sourceViewProvider: { context in
				guard let cell = self.tableView.cellForRow(at: indexPath) else { return nil }
				return cell
			})
		}
		
		present(detailNavigationController, animated: true)
	}
	
	override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		let app = sortedApps[indexPath.row]
		var actions: [UIContextualAction] = []
		
		let bundleIdentifier = app.bundleIdentifier
		
		// Only allow deletion for User apps
		if app.applicationType == "User" {
			let deleteAction = UIContextualAction(style: .destructive, title: .localized("Delete")) { _, _, completion in
				Task {
					do {
						try TrollStoreAppManager.deleteApp(bundleIdentifier: bundleIdentifier)
						await MainActor.run {
							self.sortedApps.remove(at: indexPath.row)
							
							if let fullIndex = self.apps.firstIndex(where: { $0.bundleIdentifier == bundleIdentifier }) {
								self.apps.remove(at: fullIndex)
							}
							
							self.tableView.deleteRows(at: [indexPath], with: .automatic)
							completion(true)
						}
					} catch {
						await MainActor.run {
							UIAlertController.showAlertWithOk(
								title: "Error",
								message: error.localizedDescription
							)
							completion(false)
						}
					}
				}
			}

			deleteAction.image = UIImage(systemName: "trash.fill")
			deleteAction.backgroundColor = .systemRed
			actions.append(deleteAction)
		}
		
		let openAction = UIContextualAction(style: .normal, title: .localized("Open")) { _, _, completion in
			_ = TrollStoreAppManager.openApp(bundleIdentifier: bundleIdentifier)
			completion(true)
		}
		openAction.image = UIImage(systemName: "arrow.up.forward")
		actions.append(openAction)
		
		let configuration = UISwipeActionsConfiguration(actions: actions)
		configuration.performsFirstActionWithFullSwipe = false
		
		return configuration
	}
	
	@available(iOS 17.0, *)
	override func updateContentUnavailableConfiguration(using state: UIContentUnavailableConfigurationState) {
		var config: UIContentUnavailableConfiguration?
		if sortedApps.count == 0 {
			var empty = UIContentUnavailableConfiguration.empty()
			empty.background.backgroundColor = .systemBackground
			empty.image = UIImage(systemName: "nosign.app")
			empty.text = .localized("No Apps Found")
			empty.secondaryText = "Make sure this app is installed via TrollStore to access system APIs."
			empty.background = .listSidebarCell()
			
			config = empty
			contentUnavailableConfiguration = config
			return
		} else {
			contentUnavailableConfiguration = nil
			return
		}
	}
}

extension ATAppsViewController: UISearchResultsUpdating {
	func updateSearchResults(for searchController: UISearchController) {
		guard let searchText = searchController.searchBar.text?.lowercased(), !searchText.isEmpty else {
			sortedApps = allSortedApps
			tableView.reloadData()
			return
		}
		
		sortedApps = allSortedApps.filter { app in
			app.displayName?.lowercased().contains(searchText) == true ||
			app.executableName?.lowercased().contains(searchText) == true ||
			app.bundleIdentifier.lowercased().contains(searchText) == true
		}
		tableView.reloadData()
	}
}