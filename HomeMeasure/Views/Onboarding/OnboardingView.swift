//
//  OnboardingView.swift
//  HomeMeasure
//
//  Three illustrated onboarding screens, each with a distinct interaction:
//    1. Home Goal     — tap a goal card to burst particles + select it
//    2. Control Level — drag a knob along a track to pick detail level
//    3. First Area    — scroll-driven blueprint parallax + add the first area
//
//  Looping animations are stopped on disappear. Completion writes the user's
//  choices to the store/settings and flips hasCompletedOnboarding.
//

import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var settings: AppSettings

    @State private var page = 0

    var body: some View {
        ZStack {
            BlueprintBackground()
            VStack(spacing: 0) {
                // Skip
                HStack {
                    Spacer()
                    Button("Skip") { finish() }
                        .font(.appHeadline(15))
                        .foregroundColor(Theme.textMuted)
                        .padding(.horizontal, 20).padding(.top, 8)
                }

                TabView(selection: $page) {
                    GoalScreen().tag(0)
                    DetailScreen().tag(1)
                    FirstAreaScreen(onAdd: finish).tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: page)

                // Dots
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Capsule()
                            .fill(i == page ? Theme.accent : Theme.stroke)
                            .frame(width: i == page ? 22 : 8, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: page)
                    }
                }
                .padding(.bottom, 8)

                // Primary action
                PrimaryButton(title: page == 0 ? "Next" : (page == 1 ? "Set Detail" : "Add Area")) {
                    if page < 2 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { page += 1 }
                    } else {
                        // FirstAreaScreen handles add via its own field; advance there.
                        NotificationCenter.default.post(name: .onboardingAddArea, object: nil)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private func finish() {
        // Seed a demo project only if the user added nothing, and always keep
        // the goal they chose on screen 1.
        let chosenGoal = store.goal
        if !store.hasData { SampleData.populate(store) }
        store.goal = chosenGoal
        onComplete()
    }
}

extension Notification.Name {
    static let onboardingAddArea = Notification.Name("onboardingAddArea")
}

// MARK: - Screen 1: Home Goal (tap to burst)

private struct GoalScreen: View {
    @EnvironmentObject var store: ProjectStore
    @State private var selected: HomeGoal = .refresh
    @State private var burstCount = 0
    @State private var burstAnchor: HomeGoal = .refresh

    private let cols = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Text("What are you improving?")
                    .font(.appTitle(26)).foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                Text("We'll tune the screens and templates to match your goal.")
                    .font(.appBody(14)).foregroundColor(Theme.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            LazyVGrid(columns: cols, spacing: 14) {
                ForEach(HomeGoal.allCases) { goal in
                    ZStack {
                        GoalCard(goal: goal, isSelected: selected == goal)
                        if burstAnchor == goal {
                            ParticleBurst(color: goal.tint).id(burstCount)
                        }
                    }
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            selected = goal
                            store.goal = goal
                        }
                        burstAnchor = goal
                        burstCount += 1
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    }
                }
            }
            .padding(.horizontal, 20)

            Text("Tap a goal to select it")
                .font(.appCaption(12)).foregroundColor(Theme.textMuted)
            Spacer()
        }
        .padding(.top, 12)
        .onAppear { selected = store.goal }
    }
}

private struct GoalCard: View {
    let goal: HomeGoal
    let isSelected: Bool
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: goal.icon)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(isSelected ? .white : goal.tint)
                .frame(width: 64, height: 64)
                .background(Circle().fill(isSelected ? goal.tint : goal.tint.opacity(0.15)))
                .scaleEffect(isSelected ? 1.08 : 1)
            Text(goal.title).font(.appHeadline(17)).foregroundColor(Theme.textPrimary)
            Text(goal.subtitle).font(.appCaption(12)).foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous).fill(Theme.surface))
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous)
                .stroke(isSelected ? goal.tint : Theme.stroke, lineWidth: isSelected ? 2 : 1))
    }
}

/// Finite particle burst — animates outward once on appear.
private struct ParticleBurst: View {
    let color: Color
    @State private var fire = false
    private let count = 12
    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                Circle()
                    .fill(color)
                    .frame(width: 7, height: 7)
                    .offset(x: cos(angle(i)) * (fire ? 70 : 0),
                            y: sin(angle(i)) * (fire ? 70 : 0))
                    .opacity(fire ? 0 : 1)
                    .scaleEffect(fire ? 0.2 : 1)
            }
        }
        .onAppear {
            fire = false
            withAnimation(.easeOut(duration: 0.6)) { fire = true }
        }
    }
    private func angle(_ i: Int) -> Double { (Double(i) / Double(count)) * 2 * .pi }
}

// MARK: - Screen 2: Control Level (drag knob)

private struct DetailScreen: View {
    @EnvironmentObject var settings: AppSettings
    @State private var dragX: CGFloat = 0
    @State private var trackWidth: CGFloat = 1
    @State private var isVisible = true
    @State private var glow = false

    private let levels = DetailLevel.allCases

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 8) {
                Text("Choose how detailed you want it")
                    .font(.appTitle(25)).foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Drag the marker to set how many tools appear across the app.")
                    .font(.appBody(14)).foregroundColor(Theme.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            // current level showcase
            VStack(spacing: 10) {
                Image(systemName: settings.detailLevel.icon)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 96, height: 96)
                    .background(Circle().fill(Theme.accentGradient))
                    .scaleEffect(glow ? 1.05 : 0.95)
                    .shadow(color: Theme.blue.opacity(0.4), radius: 16)
                Text(settings.detailLevel.title)
                    .font(.appTitle(22)).foregroundColor(Theme.textPrimary)
                Text(settings.detailLevel.blurb)
                    .font(.appBody(14)).foregroundColor(Theme.textMuted)
                    .multilineTextAlignment(.center)
                    .frame(height: 44)
                    .padding(.horizontal, 30)
            }

            // drag track
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surfaceAlt).frame(height: 10)
                    Capsule().fill(Theme.accentGradient)
                        .frame(width: max(20, dragX + 16), height: 10)
                    // stops
                    ForEach(0..<levels.count, id: \.self) { i in
                        Circle().fill(Theme.surface)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(Theme.stroke, lineWidth: 1))
                            .position(x: stopX(i, w), y: 5)
                    }
                    // knob
                    Circle()
                        .fill(Theme.surface)
                        .frame(width: 34, height: 34)
                        .overlay(Circle().stroke(Theme.accent, lineWidth: 3))
                        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                        .position(x: min(max(17, dragX), w - 17), y: 5)
                        .gesture(
                            DragGesture()
                                .onChanged { v in
                                    dragX = min(max(0, v.location.x), w)
                                    updateLevel(w: w)
                                }
                                .onEnded { _ in
                                    snap(w: w)
                                }
                        )
                }
                .frame(height: 34)
                .onAppear {
                    trackWidth = w
                    dragX = stopX(levels.firstIndex(of: settings.detailLevel) ?? 1, w)
                }
            }
            .frame(height: 34)
            .padding(.horizontal, 40)

            HStack {
                ForEach(levels) { lvl in
                    Text(lvl.title).font(.appCaption(12))
                        .foregroundColor(settings.detailLevel == lvl ? Theme.accent : Theme.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 30)

            Spacer()
        }
        .padding(.top, 12)
        .onAppear {
            isVisible = true
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { glow = true }
        }
        .onDisappear {
            isVisible = false
            glow = false
        }
    }

    private func stopX(_ i: Int, _ w: CGFloat) -> CGFloat {
        guard levels.count > 1 else { return w / 2 }
        let usable = w - 34
        return 17 + usable * CGFloat(i) / CGFloat(levels.count - 1)
    }
    private func updateLevel(w: CGFloat) {
        let usable = w - 34
        let ratio = max(0, min(1, (dragX - 17) / usable))
        let idx = Int((ratio * CGFloat(levels.count - 1)).rounded())
        let clamped = min(max(0, idx), levels.count - 1)
        if settings.detailLevel != levels[clamped] {
            settings.detailLevel = levels[clamped]
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
    private func snap(w: CGFloat) {
        let idx = levels.firstIndex(of: settings.detailLevel) ?? 1
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            dragX = stopX(idx, w)
        }
    }
}

// MARK: - Screen 3: First Area (scroll parallax + add)

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

private struct FirstAreaScreen: View {
    let onAdd: () -> Void
    @EnvironmentObject var store: ProjectStore
    @State private var name: String = ""
    @State private var startDate = Date()
    @State private var scrollY: CGFloat = 0
    @State private var float = false
    @State private var isVisible = true

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                GeometryReader { geo in
                    Color.clear.preference(key: ScrollOffsetKey.self,
                                           value: geo.frame(in: .named("scroll")).minY)
                }
                .frame(height: 0)

                // Parallax blueprint hero — layers shift with scroll + a gentle loop
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Theme.teal.opacity(0.6), lineWidth: 2)
                        .frame(width: 200, height: 130)
                        .offset(y: scrollY * 0.15 + (float ? -4 : 4))
                    Image(systemName: "ruler")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(Theme.accent)
                        .offset(x: scrollY * 0.25, y: -10 + (float ? -6 : 6))
                    Image(systemName: "square.split.bottomrightquarter.fill")
                        .font(.system(size: 26))
                        .foregroundColor(Theme.blue.opacity(0.7))
                        .offset(x: -60 - scrollY * 0.2, y: 30)
                }
                .frame(height: 150)
                .padding(.top, 10)

                VStack(spacing: 8) {
                    Text("Add the first work area")
                        .font(.appTitle(25)).foregroundColor(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("Name a zone and set an approximate start date so timeline analytics begin right away.")
                        .font(.appBody(14)).foregroundColor(Theme.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Card {
                    VStack(spacing: 16) {
                        AppTextField(title: "Area name", text: $name,
                                     placeholder: "e.g. Kitchen", systemImage: "square.split.bottomrightquarter.fill")
                        VStack(alignment: .leading, spacing: 6) {
                            Text("APPROXIMATE START")
                                .font(.appCaption(11)).foregroundColor(Theme.textMuted)
                            DatePicker("", selection: $startDate, displayedComponents: .date)
                                .labelsHidden()
                                .accentColor(Theme.accent)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 20)

                Text("Tip: scroll — the blueprint shifts with you.")
                    .font(.appCaption(12)).foregroundColor(Theme.textMuted)
                    .padding(.bottom, 30)
            }
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetKey.self) { scrollY = $0 }
        .onAppear {
            isVisible = true
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { float = true }
        }
        .onDisappear {
            isVisible = false
            float = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .onboardingAddArea)) { _ in
            addArea()
        }
    }

    private func addArea() {
        // Start the user's real project with their first area; onAdd() (finish)
        // seeds a demo only if they left it blank.
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            store.rooms.insert(Room(name: trimmed, type: .room, status: .notStarted,
                                    priority: .medium, targetDate: startDate), at: 0)
        }
        store.startDate = startDate
        onAdd()
    }
}
