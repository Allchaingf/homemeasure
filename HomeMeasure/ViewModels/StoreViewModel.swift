//
//  StoreViewModel.swift
//  HomeMeasure
//
//  Base class for screen view models. Each VM holds transient UI/form state
//  (@Published) and intent methods that mutate the shared ProjectStore (which
//  auto-persists). Configured from the environment in the view's .onAppear.
//

import SwiftUI

class StoreViewModel: ObservableObject {
    weak var store: ProjectStore?
    weak var settings: AppSettings?
    weak var toast: ToastCenter?
    private(set) var isConfigured = false

    func configure(_ store: ProjectStore, _ settings: AppSettings, _ toast: ToastCenter) {
        guard !isConfigured else { return }
        self.store = store
        self.settings = settings
        self.toast = toast
        isConfigured = true
        onConfigure()
    }

    /// Override for one-time setup once dependencies are available.
    func onConfigure() {}

    func confirm(_ message: String, icon: String = "checkmark.circle.fill", color: Color = Theme.success) {
        toast?.show(message, icon: icon, color: color)
    }

    func warn(_ message: String) {
        toast?.show(message, icon: "exclamationmark.triangle.fill", color: Theme.warning)
    }
}
