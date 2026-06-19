//
//  HomeMeasureApp.swift
//  HomeMeasure
//
//  App entry point. Injects the app-wide environment objects and applies the
//  user's selected color scheme. Flow: Splash → (first launch) Onboarding → Main.
//  No login / welcome / account screens anywhere.
//

import SwiftUI

@main
struct HomeMeasureApp: App {
    @StateObject private var store = ProjectStore()
    @StateObject private var settings = AppSettings()
    @StateObject private var toast = ToastCenter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(settings)
                .environmentObject(toast)
                .preferredColorScheme(settings.colorScheme)
                .toastHost(toast)
        }
    }
}
