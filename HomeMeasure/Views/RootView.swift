//
//  RootView.swift
//  HomeMeasure
//
//  Coordinates the launch flow. Splash always runs first; then either the
//  one-time onboarding (first launch) or straight into the main app.
//

import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.5)) { showSplash = false }
                }
                .transition(.opacity)
            } else if !hasCompletedOnboarding {
                OnboardingView {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        hasCompletedOnboarding = true
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
    }
}
