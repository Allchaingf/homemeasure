//
//  ProgressAnalyticsView.swift
//  HomeMeasure
//
//  Screen 9 — Progress Trends. Completion by room, stage and week, with a
//  stage filter and a compare toggle. Buttons: Filter Stage / Compare.
//

import SwiftUI

struct ProgressAnalyticsView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var toast: ToastCenter
    @StateObject private var vm = ProgressAnalyticsViewModel()
    @State private var showFilter = false

    var body: some View {
        ScreenScaffold {
            overview
            HStack(spacing: 12) {
                PrimaryButton(title: "Filter Stage", systemImage: "line.3.horizontal.decrease.circle") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showFilter.toggle() }
                }
                SecondaryButton(title: vm.compareMode ? "Hide Compare" : "Compare",
                                systemImage: "rectangle.split.2x1", tint: Theme.blue) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { vm.compareMode.toggle() }
                }
            }
            if showFilter { filterCard }
            roomChart
            stageChart
            if vm.compareMode { weeklyChart }
            if !vm.stalled.isEmpty { stalledCard }
        }
        .navigationBarTitle("Progress Trends", displayMode: .inline)
        .onAppear { vm.configure(store, settings, toast) }
    }

    private var overview: some View {
        Card {
            HStack(spacing: 18) {
                RingProgress(value: store.overallProgress, tint: Theme.accent, size: 90)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Overall progress").font(.appHeadline(16)).foregroundColor(Theme.textPrimary)
                    Text("\(store.doneTaskCount)/\(store.tasks.count) tasks done")
                        .font(.appCaption(12)).foregroundColor(Theme.textMuted)
                    Text("\(store.stages.filter { $0.status == .done }.count)/\(store.stages.count) stages complete")
                        .font(.appCaption(12)).foregroundColor(Theme.textMuted)
                }
                Spacer()
            }
        }
    }

    private var filterCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Filter by phase", systemImage: "line.3.horizontal.decrease.circle")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        SelectableChip(text: "All", isSelected: vm.phaseFilter == nil, color: Theme.accent) {
                            vm.phaseFilter = nil
                        }
                        ForEach(StagePhase.allCases) { phase in
                            SelectableChip(text: phase.title, systemImage: phase.icon,
                                           isSelected: vm.phaseFilter == phase, color: Theme.accent) {
                                vm.phaseFilter = phase
                            }
                        }
                    }
                }
            }
        }
    }

    private var roomChart: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "By room", systemImage: "square.split.bottomrightquarter.fill")
                let data = vm.roomBars()
                if data.isEmpty { Text("No rooms yet.").font(.appBody(14)).foregroundColor(Theme.textMuted) }
                else { HBarChart(data: data, normalized: true) }
            }
        }
    }

    private var stageChart: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "By stage", systemImage: "flowchart")
                let data = vm.stageBars()
                if data.isEmpty { Text("No stages match.").font(.appBody(14)).foregroundColor(Theme.textMuted) }
                else { HBarChart(data: data, normalized: true) }
            }
        }
    }

    private var weeklyChart: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Weekly completion", subtitle: "Tasks done per week", systemImage: "calendar")
                VBarChart(data: vm.weeklyCompletion())
            }
        }
    }

    private var stalledCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Where it's stuck", systemImage: "exclamationmark.triangle.fill")
                ForEach(vm.stalled, id: \.self) { name in
                    HStack(spacing: 8) {
                        Image(systemName: "tortoise.fill").foregroundColor(Theme.warning)
                        Text("\(name) — under 25% complete").font(.appBody(14)).foregroundColor(Theme.textPrimary)
                    }
                }
            }
        }
    }
}
