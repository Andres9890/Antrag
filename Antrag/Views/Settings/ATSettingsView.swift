//
//  ATSettingsView.swift
//  Antrag - TrollStore Version
//
//  Removed VPN and pairing file requirements
//

import SwiftUI

// MARK: - View
struct ATSettingsView: View {
	private let _githubUrl = "https://github.com/Andres9890/Antrag-TS"
	
	// MARK: Body
	
	var body: some View {
		NavigationStack {
			Form {
				_trollStoreInfo()
				_feedback()
				_help()
			}
			.navigationTitle(.localized("Settings"))
			.navigationBarTitleDisplayMode(.large)
		}
	}
}

// MARK: - View extension
extension ATSettingsView {
	@ViewBuilder
	private func _trollStoreInfo() -> some View {
		Section(.localized("TrollStore")) {
			HStack {
				VStack(alignment: .leading, spacing: 4) {
					Text("Native App Management")
						.font(.headline)
					Text("This app uses TrollStore's LSApplicationWorkspace APIs for direct system-level app access without requiring VPN or pairing files.")
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}
				Spacer()
				Image(systemName: "checkmark.circle.fill")
					.foregroundStyle(.green)
					.font(.title2)
			}
			.padding(.vertical, 4)
		}
	}
	
	@ViewBuilder
	private func _feedback() -> some View {
		Section {
			NavigationLink(destination: SYAboutView()) {
				Label {
					Text(verbatim: .localized("About %@", arguments: Bundle.main.name))
				} icon: {
					Image(uiImage: UIImage(named: Bundle.main.iconFileName ?? "")!)
						.appIconStyle(size: 23)
				}
			}
			Button(.localized("GitHub Repository"), systemImage: "safari") {
				UIApplication.open(_githubUrl)
			}
			#if !DISTRIBUTION
			Button(.localized("Support My Work"), systemImage: "heart") {
				UIApplication.open(_donationsUrl)
			}
			#endif
		}
	}
	
	@ViewBuilder
	private func _help() -> some View {
		Section(.localized("Help")) {
			Button(.localized("TrollStore Installation Guide"), systemImage: "questionmark.circle") {
				UIApplication.open("https://ios.cfw.guide/installing-trollstore/")
			}
			Button(.localized("Building .tipa Files"), systemImage: "hammer") {
				UIApplication.open("https://github.com/khcrysalis/Antrag#building")
			}
		}
	}
}