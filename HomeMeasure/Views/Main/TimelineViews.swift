//
//  TimelineViews.swift
//  HomeMeasure
//
//  Screen 6 — Project Timeline, Screen 18 — Build Stages,
//  Screen 19 — Task Board, Screen 20 — Crew Planner.
//

import SwiftUI

// MARK: - Timeline Calendar (Screen 6)

struct TimelineCalendarView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var toast: ToastCenter
    @StateObject private var vm = TimelineViewModel()
    @State private var showAdd = false
    @State private var showShift = false

    private var sorted: [Milestone] { store.milestones.sorted { $0.date < $1.date } }

    var body: some View {
        ScreenScaffold {
            Card {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Start").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                        Text(DateFmt.string(store.startDate)).font(.appHeadline(15)).foregroundColor(Theme.textPrimary)
                    }
                    Spacer()
                    Image(systemName: "arrow.right").foregroundColor(Theme.accent)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Projected finish").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                        Text(DateFmt.string(store.projectedFinish)).font(.appHeadline(15)).foregroundColor(Theme.accent)
                    }
                }
            }
            HStack(spacing: 12) {
                PrimaryButton(title: "Add Milestone", systemImage: "plus") { showAdd = true }
                SecondaryButton(title: "Shift Dates", systemImage: "calendar.badge.clock", tint: Theme.blue) {
                    withAnimation { showShift.toggle() }
                }
            }
            if showShift { shiftCard }
            timeline
        }
        .navigationBarTitle("Project Timeline", displayMode: .inline)
        .onAppear { vm.configure(store, settings, toast) }
        .sheet(isPresented: $showAdd) { addSheet }
    }

    private var shiftCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Shift open dates", subtitle: "Moves milestones & open tasks", systemImage: "calendar.badge.clock")
                Stepper(value: $vm.shiftDays, in: -60...60) {
                    Text("\(vm.shiftDays > 0 ? "+" : "")\(vm.shiftDays) days")
                        .font(.appHeadline(16)).foregroundColor(Theme.textPrimary)
                }
                PrimaryButton(title: "Apply Shift", systemImage: "arrow.left.arrow.right") { vm.shiftAll() }
            }
        }
    }

    private var timeline: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader(title: "Milestones", systemImage: "flag.fill")
                    .padding(.bottom, 12)
                if sorted.isEmpty {
                    Text("No milestones yet.").font(.appBody(14)).foregroundColor(Theme.textMuted)
                } else {
                    ForEach(Array(sorted.enumerated()), id: \.element.id) { idx, ms in
                        HStack(alignment: .top, spacing: 12) {
                            VStack(spacing: 0) {
                                Image(systemName: ms.done ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(ms.done ? Theme.success : (ms.date < Date() ? Theme.danger : Theme.accent))
                                    .font(.system(size: 18))
                                    .onTapGesture { vm.toggleDone(ms) }
                                if idx != sorted.count - 1 {
                                    Rectangle().fill(Theme.stroke).frame(width: 2, height: 36)
                                }
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ms.title).font(.appBody(15))
                                    .foregroundColor(Theme.textPrimary)
                                    .strikethrough(ms.done)
                                Text(DateFmt.string(ms.date)).font(.appCaption(11)).foregroundColor(Theme.textMuted)
                            }
                            Spacer()
                            Button(action: { vm.delete(ms) }) {
                                Image(systemName: "trash").font(.system(size: 12)).foregroundColor(Theme.danger)
                            }
                            .padding(.top, 2)
                        }
                    }
                }
            }
        }
    }

    private var addSheet: some View {
        FormSheet(title: "Add Milestone", saveTitle: "Add", canSave: vm.canAdd,
                  onSave: { vm.addMilestone(); showAdd = false }, onCancel: { showAdd = false }) {
            AppTextField(title: "Milestone", text: $vm.title, placeholder: "e.g. Tiling complete", systemImage: "flag")
            VStack(alignment: .leading, spacing: 6) {
                Text("DATE").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                DatePicker("", selection: $vm.date, displayedComponents: .date).labelsHidden().accentColor(Theme.accent)
            }
        }
    }
}

// MARK: - Work Stages (Screen 18)

struct WorkStagesView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var toast: ToastCenter
    @StateObject private var vm = WorkStageViewModel()
    @State private var showAdd = false

    private var sorted: [WorkStage] { store.stages.sorted { $0.order < $1.order } }

    var body: some View {
        ScreenScaffold {
            HStack(spacing: 12) {
                PrimaryButton(title: "Add Stage", systemImage: "plus") { showAdd = true }
                SecondaryButton(title: "Move Next", systemImage: "forward.fill", tint: Theme.blue) {
                    if let next = sorted.first(where: { $0.status != .done }) { vm.moveNext(next) }
                    else { vm.warn("All stages done") }
                }
            }
            if sorted.isEmpty {
                Card { EmptyStateView(systemImage: "flowchart", title: "No stages", message: "Add build stages to drive your timeline.") }
            } else {
                ForEach(sorted) { stage in stageRow(stage) }
            }
        }
        .navigationBarTitle("Build Stages", displayMode: .inline)
        .onAppear { vm.configure(store, settings, toast) }
        .sheet(isPresented: $showAdd) { addSheet }
    }

    private func stageRow(_ stage: WorkStage) -> some View {
        Card {
            HStack(spacing: 12) {
                Image(systemName: stage.phase.icon).font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white).frame(width: 42, height: 42)
                    .background(RoundedRectangle(cornerRadius: 11).fill(stage.status.tint))
                VStack(alignment: .leading, spacing: 3) {
                    Text(stage.name).font(.appHeadline(16)).foregroundColor(Theme.textPrimary)
                    Text(stage.phase.title).font(.appCaption(11)).foregroundColor(Theme.textMuted)
                }
                Spacer()
                Chip(text: stage.status.title, color: stage.status.tint, filled: true)
                Button(action: { vm.moveNext(stage) }) {
                    Image(systemName: "forward.circle.fill").font(.system(size: 24)).foregroundColor(Theme.accent)
                }
            }
            .contextMenu {
                Button(action: { vm.delete(stage) }) { Label("Delete", systemImage: "trash").foregroundColor(Theme.danger) }
            }
        }
    }

    private var addSheet: some View {
        FormSheet(title: "Add Stage", saveTitle: "Add", canSave: vm.canAdd,
                  onSave: { vm.addStage(); showAdd = false }, onCancel: { showAdd = false }) {
            AppTextField(title: "Stage name", text: $vm.name, placeholder: "e.g. Finish carpentry", systemImage: "hammer")
            VStack(alignment: .leading, spacing: 6) {
                Text("PHASE").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                EnumChips(selection: $vm.phase, title: { $0.title }, tint: Theme.accent, icon: { $0.icon })
            }
        }
    }
}

// MARK: - Task Board (Screen 19)

struct TaskBoardView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var toast: ToastCenter
    @StateObject private var vm = TaskBoardViewModel()
    @State private var showAdd = false
    @State private var dueTarget: ProjectTask? = nil

    var body: some View {
        ZStack {
            BlueprintBackground()
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    PrimaryButton(title: "New Task", systemImage: "plus") { showAdd = true }
                    SecondaryButton(title: "Set Due Date", systemImage: "calendar", tint: Theme.blue) {
                        dueTarget = store.tasks.first
                        if dueTarget == nil { vm.warn("No tasks yet") }
                    }
                }
                .padding(.horizontal, 16).padding(.top, 8)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(TaskState.allCases) { state in column(state) }
                    }
                    .padding(.horizontal, 16)
                }
                Spacer(minLength: 0)
            }
            .tabBarInset()
        }
        .navigationBarTitle("Project Tasks", displayMode: .inline)
        .onAppear { vm.configure(store, settings, toast) }
        .sheet(isPresented: $showAdd) { addSheet }
        .sheet(item: $dueTarget) { task in dueSheet(task) }
    }

    private func column(_ state: TaskState) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: state.icon).foregroundColor(state.tint)
                Text(state.title).font(.appHeadline(15)).foregroundColor(Theme.textPrimary)
                Spacer()
                Text("\(vm.tasks(in: state).count)").font(.appCaption(12)).foregroundColor(Theme.textMuted)
            }
            ForEach(vm.tasks(in: state)) { task in taskCard(task) }
            if vm.tasks(in: state).isEmpty {
                Text("Empty").font(.appCaption(12)).foregroundColor(Theme.textMuted)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surfaceAlt.opacity(0.5)))
            }
        }
        .padding(12)
        .frame(width: 250)
        .background(RoundedRectangle(cornerRadius: Metrics.radius).fill(Theme.surface.opacity(0.6)))
        .overlay(RoundedRectangle(cornerRadius: Metrics.radius).stroke(Theme.stroke, lineWidth: 1))
    }

    private func taskCard(_ task: ProjectTask) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(task.title).font(.appBody(14)).foregroundColor(Theme.textPrimary)
            HStack(spacing: 6) {
                if task.roomID != nil { Chip(text: store.roomName(task.roomID), color: Theme.blue) }
                if !task.assignee.isEmpty { InfoPill(icon: "person", text: task.assignee, tint: Theme.teal) }
            }
            HStack {
                Label(DateFmt.relativeDays(to: task.dueDate), systemImage: "calendar")
                    .font(.appCaption(11)).foregroundColor(task.dueDate < Date() && task.state != .done ? Theme.danger : Theme.textMuted)
                Spacer()
                Menu {
                    ForEach(TaskState.allCases) { s in
                        Button(action: { vm.move(task, to: s) }) { Label("Move to \(s.title)", systemImage: s.icon) }
                    }
                    Button(action: { dueTarget = task }) { Label("Set Due Date", systemImage: "calendar") }
                    Button(action: { vm.delete(task) }) { Label("Delete", systemImage: "trash").foregroundColor(Theme.danger) }
                } label: {
                    Image(systemName: "ellipsis.circle").foregroundColor(Theme.accent)
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surfaceAlt))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(task.state.tint.opacity(0.4), lineWidth: 1))
    }

    private var addSheet: some View {
        FormSheet(title: "New Task", saveTitle: "Add", canSave: vm.canAdd,
                  onSave: { vm.addTask(); showAdd = false }, onCancel: { showAdd = false }) {
            AppTextField(title: "Task", text: $vm.title, placeholder: "e.g. Install vanity", systemImage: "list.bullet")
            AppTextField(title: "Assignee", text: $vm.assignee, placeholder: "e.g. Mike", systemImage: "person")
            VStack(alignment: .leading, spacing: 6) {
                Text("ROOM").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                RoomChips(rooms: store.rooms, selection: $vm.roomID)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("DUE DATE").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                DatePicker("", selection: $vm.dueDate, displayedComponents: .date).labelsHidden().accentColor(Theme.accent)
            }
        }
    }

    private func dueSheet(_ task: ProjectTask) -> some View {
        DueDateSheet(task: task) { date in
            vm.setDueDate(date, for: task)
            dueTarget = nil
        } onCancel: { dueTarget = nil }
    }
}

private struct DueDateSheet: View {
    let task: ProjectTask
    let onSet: (Date) -> Void
    let onCancel: () -> Void
    @State private var date: Date

    init(task: ProjectTask, onSet: @escaping (Date) -> Void, onCancel: @escaping () -> Void) {
        self.task = task; self.onSet = onSet; self.onCancel = onCancel
        _date = State(initialValue: task.dueDate)
    }

    var body: some View {
        FormSheet(title: "Set Due Date", saveTitle: "Set",
                  onSave: { onSet(date) }, onCancel: onCancel) {
            Text(task.title).font(.appHeadline(16)).foregroundColor(Theme.textPrimary)
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle()).accentColor(Theme.accent)
        }
    }
}

// MARK: - Crew Planner (Screen 20)

struct CrewPlannerView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var toast: ToastCenter
    @StateObject private var vm = CrewViewModel()
    @State private var showAdd = false
    @State private var assignTarget: CrewMember? = nil

    var body: some View {
        ScreenScaffold {
            PrimaryButton(title: "Add Assignment", systemImage: "person.crop.circle.badge.plus") { showAdd = true }
            if store.crew.isEmpty {
                Card { EmptyStateView(systemImage: "person.2", title: "No assignments",
                                      message: "Add people as text notes (owner, contractor, helper) — no accounts needed.") }
            } else {
                ForEach(store.crew) { member in memberCard(member) }
            }
        }
        .navigationBarTitle("Work Assignments", displayMode: .inline)
        .onAppear { vm.configure(store, settings, toast) }
        .sheet(isPresented: $showAdd) { addSheet }
        .sheet(item: $assignTarget) { member in assignSheet(member) }
    }

    private func memberCard(_ member: CrewMember) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: member.role.icon).font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white).frame(width: 42, height: 42)
                        .background(Circle().fill(member.role.tint))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.name).font(.appHeadline(16)).foregroundColor(Theme.textPrimary)
                        if !member.note.isEmpty {
                            Text(member.note).font(.appCaption(11)).foregroundColor(Theme.textMuted)
                        }
                    }
                    Spacer()
                    Menu {
                        ForEach(CrewRole.allCases) { r in
                            Button(action: { vm.setRole(r, for: member) }) { Label(r.title, systemImage: r.icon) }
                        }
                    } label: { Chip(text: member.role.title, color: member.role.tint, filled: true) }
                }
                let assigned = store.tasks.filter { $0.assignee == member.name }
                if !assigned.isEmpty {
                    ForEach(assigned) { t in
                        HStack(spacing: 6) {
                            Image(systemName: t.state.icon).foregroundColor(t.state.tint).font(.system(size: 11))
                            Text(t.title).font(.appCaption(12)).foregroundColor(Theme.textSecondary).lineLimit(1)
                            Spacer()
                        }
                    }
                }
                HStack {
                    Button(action: { assignTarget = member }) {
                        Label("Assign Task", systemImage: "arrow.right.circle.fill").font(.appCaption(13)).foregroundColor(Theme.accent)
                    }
                    Spacer()
                    Button(action: { vm.delete(member) }) {
                        Image(systemName: "trash").font(.system(size: 13)).foregroundColor(Theme.danger)
                    }
                }
            }
        }
    }

    private var addSheet: some View {
        FormSheet(title: "Add Assignment", saveTitle: "Add", canSave: vm.canAdd,
                  onSave: { vm.addMember(); showAdd = false }, onCancel: { showAdd = false }) {
            AppTextField(title: "Name", text: $vm.name, placeholder: "e.g. Mike", systemImage: "person")
            VStack(alignment: .leading, spacing: 6) {
                Text("ROLE").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                EnumChips(selection: $vm.role, title: { $0.title }, tint: Theme.accent, icon: { $0.icon })
            }
            AppTextField(title: "Note", text: $vm.note, placeholder: "e.g. Electrician", systemImage: "text.alignleft")
        }
    }

    private func assignSheet(_ member: CrewMember) -> some View {
        FormSheet(title: "Assign to \(member.name)", saveTitle: "Done",
                  onSave: { assignTarget = nil }, onCancel: { assignTarget = nil }) {
            Text("Tap a task to assign it to \(member.name).").font(.appBody(14)).foregroundColor(Theme.textMuted)
            ForEach(vm.unassignedTasks()) { task in
                Button(action: { vm.assign(task, to: member) }) {
                    HStack {
                        Image(systemName: task.state.icon).foregroundColor(task.state.tint)
                        Text(task.title).font(.appBody(15)).foregroundColor(Theme.textPrimary)
                        Spacer()
                        if task.assignee == member.name {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.success)
                        } else if !task.assignee.isEmpty {
                            Text(task.assignee).font(.appCaption(11)).foregroundColor(Theme.textMuted)
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surfaceAlt))
                }
            }
        }
    }
}
