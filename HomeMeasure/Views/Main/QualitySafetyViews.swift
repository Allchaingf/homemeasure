//
//  QualitySafetyViews.swift
//  HomeMeasure
//
//  Screen 3 — Issue Log, Screen 7 — Quality Check, Screen 8 — Punch List,
//  Screen 21 — Safety Checklist, Screen 22 — Tool Inventory,
//  Screen 4 — Photo Markup.
//

import SwiftUI

// MARK: - Issue Log (Screen 3)

struct IssueLogView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var toast: ToastCenter
    @StateObject private var vm = IssueViewModel()
    @State private var showAdd = false

    var body: some View {
        ScreenScaffold {
            HStack(spacing: 12) {
                PrimaryButton(title: "Add Issue", systemImage: "plus") { showAdd = true }
                SecondaryButton(title: "Resolve", systemImage: "checkmark.circle", tint: Theme.success) {
                    if let open = store.issues.first(where: { !$0.resolved }) { vm.resolve(open) }
                    else { vm.warn("No open issues") }
                }
            }
            if store.issues.isEmpty {
                Card { EmptyStateView(systemImage: "exclamationmark.bubble", title: "No issues",
                                      message: "Log defects, delays and blockers — high ones surface on the Dashboard.") }
            } else {
                ForEach(store.issues) { issue in issueRow(issue) }
            }
        }
        .navigationBarTitle("Issues & Blockers", displayMode: .inline)
        .onAppear { vm.configure(store, settings, toast) }
        .sheet(isPresented: $showAdd) { addSheet }
    }

    private func issueRow(_ issue: Issue) -> some View {
        Card {
            HStack(spacing: 12) {
                Image(systemName: issue.resolved ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 10).fill(issue.resolved ? Theme.success : issue.severity.tint))
                VStack(alignment: .leading, spacing: 3) {
                    Text(issue.title).font(.appHeadline(15)).foregroundColor(Theme.textPrimary)
                        .strikethrough(issue.resolved)
                    HStack(spacing: 6) {
                        Chip(text: issue.severity.title, color: issue.severity.tint)
                        if issue.roomID != nil { Chip(text: store.roomName(issue.roomID), color: Theme.blue) }
                    }
                    if !issue.note.isEmpty {
                        Text(issue.note).font(.appCaption(11)).foregroundColor(Theme.textMuted).lineLimit(2)
                    }
                }
                Spacer()
                VStack(spacing: 10) {
                    Button(action: { vm.resolve(issue) }) {
                        Image(systemName: issue.resolved ? "arrow.uturn.backward.circle" : "checkmark.circle.fill")
                            .font(.system(size: 22)).foregroundColor(issue.resolved ? Theme.textMuted : Theme.success)
                    }
                    Button(action: { vm.delete(issue) }) {
                        Image(systemName: "trash").font(.system(size: 13)).foregroundColor(Theme.danger)
                    }
                }
            }
        }
    }

    private var addSheet: some View {
        FormSheet(title: "Add Issue", saveTitle: "Add", canSave: vm.canAdd,
                  onSave: { vm.addIssue(); showAdd = false }, onCancel: { showAdd = false }) {
            AppTextField(title: "Issue", text: $vm.title, placeholder: "e.g. Leaking pipe", systemImage: "exclamationmark.triangle")
            VStack(alignment: .leading, spacing: 6) {
                Text("SEVERITY").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                EnumChips(selection: $vm.severity, title: { $0.title }, tint: Theme.danger)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("ROOM").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                RoomChips(rooms: store.rooms, selection: $vm.roomID)
            }
            AppTextField(title: "Note", text: $vm.note, placeholder: "Details…", systemImage: "text.alignleft")
        }
    }
}

// MARK: - Quality Check (Screen 7)

struct QualityCheckView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var toast: ToastCenter
    @StateObject private var vm = QualityViewModel()
    @State private var showAdd = false
    @State private var evidenceTarget: QualityCriterion? = nil

    var body: some View {
        ScreenScaffold {
            if let summary = vm.reviewSummary {
                Card {
                    HStack {
                        Image(systemName: "checkmark.seal.fill").foregroundColor(Theme.success)
                        Text(summary).font(.appHeadline(16)).foregroundColor(Theme.textPrimary)
                        Spacer()
                    }
                }
            }
            HStack(spacing: 12) {
                PrimaryButton(title: "Run Review", systemImage: "checkmark.circle") { vm.runReview() }
                SecondaryButton(title: "Add Criterion", systemImage: "plus", tint: Theme.blue) { showAdd = true }
            }
            if store.qualityCriteria.isEmpty {
                Card { EmptyStateView(systemImage: "list.bullet", title: "No criteria",
                                      message: "Add quality checks like level, finish and evidence.") }
            } else {
                ForEach(store.qualityCriteria) { c in criterionRow(c) }
            }
        }
        .navigationBarTitle("Quality Criteria", displayMode: .inline)
        .onAppear { vm.configure(store, settings, toast) }
        .sheet(isPresented: $showAdd) { addSheet }
        .sheet(item: $evidenceTarget) { c in evidenceSheet(c) }
    }

    private func criterionRow(_ c: QualityCriterion) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Button(action: { vm.togglePass(c) }) {
                        Image(systemName: c.passed ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22)).foregroundColor(c.passed ? Theme.success : Theme.textMuted)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(c.title).font(.appHeadline(15)).foregroundColor(Theme.textPrimary)
                        Text(store.roomName(c.roomID)).font(.appCaption(11)).foregroundColor(Theme.textMuted)
                    }
                    Spacer()
                    Button(action: { vm.delete(c) }) {
                        Image(systemName: "trash").font(.system(size: 13)).foregroundColor(Theme.danger)
                    }
                }
                StarRating(rating: c.rating) { vm.setRating($0, for: c) }
                if !c.evidence.isEmpty {
                    Text("📎 \(c.evidence)").font(.appCaption(12)).foregroundColor(Theme.textSecondary)
                }
                Button(action: { evidenceTarget = c }) {
                    Label(c.evidence.isEmpty ? "Add Evidence" : "Edit Evidence", systemImage: "paperclip")
                        .font(.appCaption(13)).foregroundColor(Theme.accent)
                }
            }
        }
    }

    private var addSheet: some View {
        FormSheet(title: "Add Criterion", saveTitle: "Add", canSave: vm.canAdd,
                  onSave: { vm.addCriterion(); showAdd = false }, onCancel: { showAdd = false }) {
            AppTextField(title: "Criterion", text: $vm.title, placeholder: "e.g. Floor level within 3mm", systemImage: "list.bullet")
            VStack(alignment: .leading, spacing: 6) {
                Text("ROOM").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                RoomChips(rooms: store.rooms, selection: $vm.roomID)
            }
        }
    }

    private func evidenceSheet(_ c: QualityCriterion) -> some View {
        EvidenceSheet(initial: c.evidence) { text in
            vm.setEvidence(text, for: c); evidenceTarget = nil
        } onCancel: { evidenceTarget = nil }
    }
}

private struct EvidenceSheet: View {
    let onSave: (String) -> Void
    let onCancel: () -> Void
    @State private var text: String
    init(initial: String, onSave: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.onSave = onSave; self.onCancel = onCancel
        _text = State(initialValue: initial)
    }
    var body: some View {
        FormSheet(title: "Evidence", saveTitle: "Save",
                  onSave: { onSave(text) }, onCancel: onCancel) {
            Text("Describe the proof (measurement, photo ref, comment).")
                .font(.appBody(14)).foregroundColor(Theme.textMuted)
            TextEditor(text: $text)
                .frame(height: 120).padding(8)
                .background(RoundedRectangle(cornerRadius: Metrics.radiusSmall).fill(Theme.surfaceAlt))
                .overlay(RoundedRectangle(cornerRadius: Metrics.radiusSmall).stroke(Theme.stroke, lineWidth: 1))
                .font(.appBody(15))
        }
    }
}

// MARK: - Punch List (Screen 8)

struct PunchListView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var toast: ToastCenter
    @StateObject private var vm = PunchListViewModel()
    @State private var showAdd = false

    var body: some View {
        ScreenScaffold {
            Card {
                HStack {
                    Text("Open items").font(.appBody(14)).foregroundColor(Theme.textSecondary)
                    Spacer()
                    Text("\(store.openPunchCount) / \(store.punchItems.count)")
                        .font(.appHeadline(16)).foregroundColor(store.openPunchCount == 0 ? Theme.success : Theme.accent)
                }
            }
            HStack(spacing: 12) {
                PrimaryButton(title: "Add Punch Item", systemImage: "plus") { showAdd = true }
                SecondaryButton(title: "Mark Closed", systemImage: "checkmark.circle", tint: Theme.success) {
                    if let open = store.punchItems.first(where: { !$0.closed }) { vm.toggleClosed(open) }
                    else { vm.warn("All items closed") }
                }
            }
            if store.punchItems.isEmpty {
                Card { EmptyStateView(systemImage: "checkmark.circle.fill", title: "No punch items",
                                      message: "Track final fixes so nothing closes early.") }
            } else {
                ForEach(store.punchItems) { item in punchRow(item) }
            }
        }
        .navigationBarTitle("Final Punch List", displayMode: .inline)
        .onAppear { vm.configure(store, settings, toast) }
        .sheet(isPresented: $showAdd) { addSheet }
    }

    private func punchRow(_ item: PunchItem) -> some View {
        Card {
            HStack(spacing: 12) {
                Button(action: { vm.toggleClosed(item) }) {
                    Image(systemName: item.closed ? "checkmark.square.fill" : "square")
                        .font(.system(size: 22)).foregroundColor(item.closed ? Theme.success : Theme.textMuted)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title).font(.appBody(15)).foregroundColor(Theme.textPrimary).strikethrough(item.closed)
                    Text(store.roomName(item.roomID)).font(.appCaption(11)).foregroundColor(Theme.textMuted)
                }
                Spacer()
                Button(action: { vm.delete(item) }) {
                    Image(systemName: "trash").font(.system(size: 13)).foregroundColor(Theme.danger)
                }
            }
        }
    }

    private var addSheet: some View {
        FormSheet(title: "Add Punch Item", saveTitle: "Add", canSave: vm.canAdd,
                  onSave: { vm.addItem(); showAdd = false }, onCancel: { showAdd = false }) {
            AppTextField(title: "Item", text: $vm.title, placeholder: "e.g. Touch up paint", systemImage: "list.bullet")
            VStack(alignment: .leading, spacing: 6) {
                Text("ROOM").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                RoomChips(rooms: store.rooms, selection: $vm.roomID)
            }
        }
    }
}

// MARK: - Safety Checklist (Screen 21)

struct SafetyChecklistView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var toast: ToastCenter
    @StateObject private var vm = SafetyViewModel()
    @State private var showAdd = false

    var body: some View {
        ScreenScaffold {
            HStack(spacing: 12) {
                PrimaryButton(title: "Run Check", systemImage: "checkmark.shield") { vm.runCheck() }
                SecondaryButton(title: "Flag Hazard", systemImage: "flag.fill", tint: Theme.danger) {
                    if let item = store.safetyItems.first(where: { !$0.flagged }) { vm.toggleFlag(item) }
                    else { vm.warn("All items flagged") }
                }
            }
            HStack {
                SecondaryButton(title: "Add Check", systemImage: "plus", tint: Theme.blue) { showAdd = true }
            }
            if store.safetyItems.isEmpty {
                Card { EmptyStateView(systemImage: "shield", title: "No checks",
                                      message: "Add safety checks for electrical, ladders, dust, tools and access.") }
            } else {
                ForEach(store.safetyItems) { item in safetyRow(item) }
            }
        }
        .navigationBarTitle("Safety Check", displayMode: .inline)
        .onAppear { vm.configure(store, settings, toast) }
        .sheet(isPresented: $showAdd) { addSheet }
    }

    private func safetyRow(_ item: SafetyItem) -> some View {
        Card {
            HStack(spacing: 12) {
                Button(action: { vm.toggleCheck(item) }) {
                    Image(systemName: item.checked ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22)).foregroundColor(item.checked ? Theme.success : Theme.textMuted)
                }
                Image(systemName: item.category.icon).foregroundColor(Theme.blue).frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title).font(.appBody(15)).foregroundColor(Theme.textPrimary)
                    Text(item.category.title).font(.appCaption(11)).foregroundColor(Theme.textMuted)
                }
                Spacer()
                Button(action: { vm.toggleFlag(item) }) {
                    Image(systemName: item.flagged ? "flag.fill" : "flag")
                        .font(.system(size: 18)).foregroundColor(item.flagged ? Theme.danger : Theme.textMuted)
                }
                Button(action: { vm.delete(item) }) {
                    Image(systemName: "trash").font(.system(size: 13)).foregroundColor(Theme.danger)
                }
            }
        }
    }

    private var addSheet: some View {
        FormSheet(title: "Add Check", saveTitle: "Add",
                  canSave: !vm.newTitle.trimmingCharacters(in: .whitespaces).isEmpty,
                  onSave: { vm.addItem(); showAdd = false }, onCancel: { showAdd = false }) {
            AppTextField(title: "Check", text: $vm.newTitle, placeholder: "e.g. Fire extinguisher on site", systemImage: "shield")
            VStack(alignment: .leading, spacing: 6) {
                Text("CATEGORY").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                EnumChips(selection: $vm.newCategory, title: { $0.title }, tint: Theme.blue, icon: { $0.icon })
            }
        }
    }
}

// MARK: - Tool Inventory (Screen 22)

struct ToolInventoryView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var toast: ToastCenter
    @StateObject private var vm = ToolViewModel()
    @State private var showAdd = false

    var body: some View {
        ScreenScaffold {
            HStack(spacing: 12) {
                PrimaryButton(title: "Add Tool", systemImage: "plus") { showAdd = true }
                SecondaryButton(title: "Set Status", systemImage: "arrow.triangle.2.circlepath", tint: Theme.blue) {
                    if let first = store.tools.first { vm.cycleStatus(first) } else { vm.warn("No tools yet") }
                }
            }
            if store.tools.isEmpty {
                Card { EmptyStateView(systemImage: "wrench.and.screwdriver", title: "No tools",
                                      message: "Track tools, rentals and consumables and their status.") }
            } else {
                ForEach(store.tools) { tool in toolRow(tool) }
            }
        }
        .navigationBarTitle("Tools & Equipment", displayMode: .inline)
        .onAppear { vm.configure(store, settings, toast) }
        .sheet(isPresented: $showAdd) { addSheet }
    }

    private func toolRow(_ tool: Tool) -> some View {
        Card {
            HStack(spacing: 12) {
                Image(systemName: "wrench.and.screwdriver.fill").font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white).frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 10).fill(tool.status.tint))
                VStack(alignment: .leading, spacing: 3) {
                    Text(tool.name).font(.appHeadline(15)).foregroundColor(Theme.textPrimary)
                    HStack(spacing: 6) {
                        if tool.isRental { Chip(text: "Rental", color: Theme.purple) }
                        if !tool.note.isEmpty { Text(tool.note).font(.appCaption(11)).foregroundColor(Theme.textMuted).lineLimit(1) }
                    }
                }
                Spacer()
                Button(action: { vm.cycleStatus(tool) }) {
                    Chip(text: tool.status.title, color: tool.status.tint, filled: true)
                }
                Button(action: { vm.delete(tool) }) {
                    Image(systemName: "trash").font(.system(size: 13)).foregroundColor(Theme.danger)
                }
            }
        }
    }

    private var addSheet: some View {
        FormSheet(title: "Add Tool", saveTitle: "Add", canSave: vm.canAdd,
                  onSave: { vm.add(); showAdd = false }, onCancel: { showAdd = false }) {
            AppTextField(title: "Tool", text: $vm.name, placeholder: "e.g. Tile saw", systemImage: "wrench.and.screwdriver.fill")
            VStack(alignment: .leading, spacing: 6) {
                Text("STATUS").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                EnumChips(selection: $vm.status, title: { $0.title }, tint: Theme.accent)
            }
            Toggle(isOn: $vm.isRental) {
                Text("Rental item").font(.appBody(15)).foregroundColor(Theme.textPrimary)
            }.toggleStyle(SwitchToggleStyle(tint: Theme.accent))
            AppTextField(title: "Note", text: $vm.note, placeholder: "Optional", systemImage: "text.alignleft")
        }
    }
}

// MARK: - Photo Markup (Screen 4)

struct PhotoMarkupView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var toast: ToastCenter
    @StateObject private var vm = PhotoMarkupViewModel()

    var body: some View {
        ScreenScaffold {
            Card {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader(title: "Mark a problem spot", subtitle: "Drag the pin onto the issue", systemImage: "mappin.and.ellipse")
                    canvas
                    AppTextField(title: "Title", text: $vm.title, placeholder: "e.g. Crack near window", systemImage: "tag")
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ROOM").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                        RoomChips(rooms: store.rooms, selection: $vm.roomID)
                    }
                    AppTextField(title: "Problem", text: $vm.problem, placeholder: "What's wrong?", systemImage: "exclamationmark.bubble")
                    HStack(spacing: 12) {
                        SecondaryButton(title: "Attach Photo", systemImage: "photo.on.rectangle", tint: Theme.blue) { vm.cyclePhoto() }
                        PrimaryButton(title: "Mark Problem", systemImage: "mappin") { vm.markProblem() }
                    }
                }
            }
            saved
        }
        .navigationBarTitle("Site Photo Notes", displayMode: .inline)
        .onAppear { vm.configure(store, settings, toast) }
    }

    private var canvas: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: vm.backdrops[vm.backdropIndex].map { Color(hex: $0) },
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                BlueprintGrid(minorSpacing: 24).stroke(Color.white.opacity(0.10), lineWidth: 0.6)
                Image(systemName: "photo")
                    .font(.system(size: 30)).foregroundColor(.white.opacity(0.25))
                // Marker
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 34)).foregroundColor(Theme.accent)
                    .background(Circle().fill(Color.white).frame(width: 18, height: 18))
                    .position(x: CGFloat(vm.markerX) * geo.size.width,
                              y: CGFloat(vm.markerY) * geo.size.height)
                    .gesture(DragGesture().onChanged { v in
                        vm.markerX = min(1, max(0, Double(v.location.x / geo.size.width)))
                        vm.markerY = min(1, max(0, Double(v.location.y / geo.size.height)))
                    })
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .frame(height: 200)
    }

    private var saved: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Saved notes", subtitle: "\(store.photoNotes.count) total", systemImage: "photo.stack")
                if store.photoNotes.isEmpty {
                    Text("No notes yet.").font(.appBody(14)).foregroundColor(Theme.textMuted)
                } else {
                    ForEach(store.photoNotes) { note in noteRow(note) }
                }
            }
        }
    }

    private func noteRow(_ note: PhotoNote) -> some View {
        HStack(spacing: 12) {
            ZStack {
                LinearGradient(colors: [Color(hex: "3A5F7D"), Color(hex: "1E3A52")],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: "mappin.circle.fill").foregroundColor(Theme.accent)
                    .position(x: CGFloat(note.markerX) * 56, y: CGFloat(note.markerY) * 44)
            }
            .frame(width: 56, height: 44).clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(note.title).font(.appBody(15)).foregroundColor(Theme.textPrimary)
                Text(note.problem.isEmpty ? store.roomName(note.roomID) : note.problem)
                    .font(.appCaption(11)).foregroundColor(Theme.textMuted).lineLimit(1)
            }
            Spacer()
            if note.linkedToPunch {
                Image(systemName: "list.bullet").foregroundColor(Theme.success)
            } else {
                Button(action: { vm.sendToPunch(note) }) {
                    Image(systemName: "arrow.right.circle.fill").foregroundColor(Theme.accent)
                }
            }
            Button(action: { vm.delete(note) }) {
                Image(systemName: "trash").font(.system(size: 13)).foregroundColor(Theme.danger)
            }
        }
    }
}
