//
//  DashboardView.swift
//  HomeMeasure
//
//  Screen 1 — Project Overview. The hub showing progress, budget, risks and
//  upcoming actions at a glance. Buttons: Add Task / Open Analytics.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var toast: ToastCenter
    @StateObject private var vm = DashboardViewModel()
    @State private var showAddTask = false

    var body: some View {
        ScreenScaffold {
            header
            statGrid
            actionRow
            if !store.risks.isEmpty { riskCenter }
            upcomingCard
            roomsCard
            stagesCard
        }
        .navigationBarTitle("Project Overview", displayMode: .inline)
        .onAppear { vm.configure(store, settings, toast) }
        .sheet(isPresented: $showAddTask) { addTaskSheet }
    }

    // MARK: Header
    private var header: some View {
        Card {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(store.projectName).font(.appTitle(22)).foregroundColor(Theme.textPrimary)
                    HStack(spacing: 6) {
                        Image(systemName: store.goal.icon).font(.system(size: 11, weight: .bold))
                        Text("Goal: \(store.goal.title)")
                    }
                    .font(.appCaption(12)).foregroundColor(store.goal.tint)
                    Text("Finish ~ \(DateFmt.string(store.projectedFinish))")
                        .font(.appCaption(12)).foregroundColor(Theme.textMuted)
                }
                Spacer()
                RingProgress(value: store.overallProgress, tint: Theme.accent, size: 84)
            }
        }
    }

    // MARK: Stat grid
    private var statGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            StatTile(title: "Work areas", value: "\(store.rooms.count)",
                     systemImage: "square.split.bottomrightquarter.fill", tint: Theme.blue)
            StatTile(title: "Total area", value: settings.area(store.totalArea),
                     systemImage: "ruler.fill", tint: Theme.teal)
            StatTile(title: "Planned budget", value: settings.money(store.plannedTotal),
                     systemImage: "dollarsign.circle.fill", tint: Theme.accent)
            StatTile(title: "Open risks", value: "\(store.riskCount)",
                     systemImage: "exclamationmark.triangle.fill",
                     tint: store.riskCount > 0 ? Theme.danger : Theme.success)
        }
    }

    // MARK: Action row
    private var actionRow: some View {
        HStack(spacing: 12) {
            PrimaryButton(title: "Add Task", systemImage: "plus") { showAddTask = true }
            NavigationLink(destination: ProgressAnalyticsView()) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Open Analytics").font(.appHeadline(16))
                }
                .foregroundColor(Theme.blue)
                .padding(.vertical, 14).frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: Metrics.radiusSmall, style: .continuous).fill(Theme.blue.opacity(0.12)))
                .overlay(RoundedRectangle(cornerRadius: Metrics.radiusSmall, style: .continuous).stroke(Theme.blue.opacity(0.5), lineWidth: 1))
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    // MARK: Risk center
    private var riskCenter: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Risk Center", subtitle: "\(store.riskCount) items need attention",
                              systemImage: "exclamationmark.triangle.fill")
                ForEach(store.risks.prefix(4)) { r in
                    HStack(spacing: 10) {
                        Image(systemName: r.icon).foregroundColor(r.tint).frame(width: 22)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(r.title).font(.appBody(14)).foregroundColor(Theme.textPrimary).lineLimit(1)
                            Text(r.detail).font(.appCaption(11)).foregroundColor(Theme.textMuted)
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: Upcoming
    private var upcomingCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Upcoming Actions", systemImage: "calendar")
                if store.upcoming.isEmpty {
                    Text("Nothing scheduled.").font(.appBody(14)).foregroundColor(Theme.textMuted)
                } else {
                    ForEach(store.upcoming.prefix(5)) { item in
                        HStack(spacing: 10) {
                            Image(systemName: item.icon).foregroundColor(item.tint).frame(width: 22)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.title).font(.appBody(14)).foregroundColor(Theme.textPrimary).lineLimit(1)
                                Text(item.subtitle).font(.appCaption(11)).foregroundColor(Theme.textMuted)
                            }
                            Spacer()
                            Text(DateFmt.relativeDays(to: item.date))
                                .font(.appCaption(11)).foregroundColor(Theme.textSecondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: Rooms
    private var roomsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Rooms", subtitle: "Tap a tab to manage", systemImage: "square.split.bottomrightquarter.fill")
                if store.rooms.isEmpty {
                    Text("No rooms yet.").font(.appBody(14)).foregroundColor(Theme.textMuted)
                } else {
                    ForEach(store.rooms.prefix(5)) { room in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Circle().fill(Color(hex: room.colorHex)).frame(width: 10, height: 10)
                                Text(room.name).font(.appBody(14)).foregroundColor(Theme.textPrimary)
                                Spacer()
                                Text("\(Int(store.progress(forRoom: room.id) * 100))%")
                                    .font(.appCaption(12)).foregroundColor(Theme.textSecondary)
                            }
                            ProgressBar(value: store.progress(forRoom: room.id), tint: Color(hex: room.colorHex), height: 8)
                        }
                    }
                }
            }
        }
    }

    // MARK: Stages
    private var stagesCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Build Stages", systemImage: "flowchart")
                ForEach(store.stages.sorted { $0.order < $1.order }) { stage in
                    HStack(spacing: 10) {
                        Image(systemName: stage.phase.icon).foregroundColor(stage.status.tint).frame(width: 22)
                        Text(stage.name).font(.appBody(14)).foregroundColor(Theme.textPrimary)
                        Spacer()
                        Chip(text: stage.status.title, color: stage.status.tint)
                    }
                }
            }
        }
    }

    // MARK: Add Task sheet
    private var addTaskSheet: some View {
        FormSheet(title: "Add Task", saveTitle: "Add", canSave: vm.canAdd,
                  onSave: { vm.addQuickTask(); showAddTask = false },
                  onCancel: { showAddTask = false }) {
            AppTextField(title: "Task", text: $vm.quickTask, placeholder: "e.g. Order tiles", systemImage: "list.bullet")
            VStack(alignment: .leading, spacing: 6) {
                Text("ROOM").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                RoomChips(rooms: store.rooms, selection: $vm.roomID)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("DUE DATE").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                DatePicker("", selection: $vm.dueDate, displayedComponents: .date)
                    .labelsHidden().accentColor(Theme.accent)
            }
        }
    }
}
