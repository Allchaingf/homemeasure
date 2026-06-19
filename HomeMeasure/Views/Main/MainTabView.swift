//
//  MainTabView.swift
//  HomeMeasure
//
//  The main app shell: a custom, theme-styled tab bar over five primary
//  sections. Every other screen is reachable through the "More" hub or via
//  navigation links, so all 23 functional screens are always one tap away.
//

import SwiftUI

// Bottom inset so floating tab bar never covers content.
extension View {
    func tabBarInset() -> some View { self.padding(.bottom, 96) }
}

struct MainTabView: View {
    @State private var selected = 0

    init() {
        // Theme the navigation bars to match the blueprint look.
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.bg)
        appearance.shadowColor = UIColor(Theme.stroke)
        appearance.titleTextAttributes = [.foregroundColor: UIColor(Theme.textPrimary)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Theme.textPrimary)]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(Theme.accent)
        // Let custom-styled TextEditors show their own background.
        UITextView.appearance().backgroundColor = .clear
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                tab(0) { NavigationView { DashboardView() }.navigationViewStyle(StackNavigationViewStyle()) }
                tab(1) { NavigationView { RoomBuilderView() }.navigationViewStyle(StackNavigationViewStyle()) }
                tab(2) { NavigationView { MeasurementPadView() }.navigationViewStyle(StackNavigationViewStyle()) }
                tab(3) { NavigationView { EstimateBuilderView() }.navigationViewStyle(StackNavigationViewStyle()) }
                tab(4) { NavigationView { MoreView() }.navigationViewStyle(StackNavigationViewStyle()) }
            }
            CustomTabBar(selected: $selected)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private func tab<Content: View>(_ index: Int, @ViewBuilder content: () -> Content) -> some View {
        content()
            .opacity(selected == index ? 1 : 0)
            .allowsHitTesting(selected == index)
            .zIndex(selected == index ? 1 : 0)
    }
}

private struct TabItem {
    let icon: String
    let label: String
}

struct CustomTabBar: View {
    @Binding var selected: Int

    private let items = [
        TabItem(icon: "rectangle.3.offgrid.fill", label: "Dashboard"),
        TabItem(icon: "square.split.bottomrightquarter.fill", label: "Rooms"),
        TabItem(icon: "ruler.fill", label: "Measure"),
        TabItem(icon: "dollarsign.circle.fill", label: "Budget"),
        TabItem(icon: "square.grid.2x2.fill", label: "More")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { selected = idx }
                    UISelectionFeedbackGenerator().selectionChanged()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .scaleEffect(selected == idx ? 1.15 : 1)
                        Text(item.label)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(selected == idx ? Theme.accent : Theme.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        VStack {
                            if selected == idx {
                                Capsule().fill(Theme.accent)
                                    .frame(width: 26, height: 3)
                                    .transition(.scale)
                            }
                            Spacer()
                        }
                    )
                }
                .buttonStyle(ScaleButtonStyle(scale: 0.9))
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 6)
        .background(
            Rectangle()
                .fill(Theme.surface)
                .overlay(Rectangle().fill(Theme.stroke).frame(height: 1), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: .black.opacity(0.08), radius: 10, y: -4)
        )
    }
}
