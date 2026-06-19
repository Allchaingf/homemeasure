//
//  ProjectStore.swift
//  HomeMeasure
//
//  The single source of truth for all project data. An ObservableObject
//  injected app-wide via @EnvironmentObject. Every @Published change is
//  persisted to UserDefaults as JSON, so data survives relaunches with no
//  server, account or login of any kind — purely local working records.
//

import SwiftUI
import Combine

// Small presentation helpers surfaced on the Dashboard.
struct RiskItem: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let icon: String
    let tint: Color
}

struct UpcomingItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let date: Date
    let icon: String
    let tint: Color
}

/// Codable mirror of the whole store used for persistence.
private struct StoreSnapshot: Codable {
    var projectName: String
    var goal: HomeGoal
    var startDate: Date
    var rooms: [Room]
    var measurements: [Measurement]
    var materials: [Material]
    var quotes: [Quote]
    var issues: [Issue]
    var photoNotes: [PhotoNote]
    var documents: [ProjectDocument]
    var milestones: [Milestone]
    var qualityCriteria: [QualityCriterion]
    var punchItems: [PunchItem]
    var estimateLines: [EstimateLine]
    var budgetLimits: [BudgetLimit]
    var stages: [WorkStage]
    var tasks: [ProjectTask]
    var crew: [CrewMember]
    var safetyItems: [SafetyItem]
    var tools: [Tool]
}

final class ProjectStore: ObservableObject {

    private let storageKey = "home_measure_store_v2"
    private var isReady = false

    // Project meta -------------------------------------------------------
    @Published var projectName: String = "My Renovation" { didSet { persist() } }
    @Published var goal: HomeGoal = .refresh { didSet { persist() } }
    @Published var startDate: Date = Date() { didSet { persist() } }

    // Collections --------------------------------------------------------
    @Published var rooms: [Room] = [] { didSet { persist() } }
    @Published var measurements: [Measurement] = [] { didSet { persist() } }
    @Published var materials: [Material] = [] { didSet { persist() } }
    @Published var quotes: [Quote] = [] { didSet { persist() } }
    @Published var issues: [Issue] = [] { didSet { persist() } }
    @Published var photoNotes: [PhotoNote] = [] { didSet { persist() } }
    @Published var documents: [ProjectDocument] = [] { didSet { persist() } }
    @Published var milestones: [Milestone] = [] { didSet { persist() } }
    @Published var qualityCriteria: [QualityCriterion] = [] { didSet { persist() } }
    @Published var punchItems: [PunchItem] = [] { didSet { persist() } }
    @Published var estimateLines: [EstimateLine] = [] { didSet { persist() } }
    @Published var budgetLimits: [BudgetLimit] = [] { didSet { persist() } }
    @Published var stages: [WorkStage] = [] { didSet { persist() } }
    @Published var tasks: [ProjectTask] = [] { didSet { persist() } }
    @Published var crew: [CrewMember] = [] { didSet { persist() } }
    @Published var safetyItems: [SafetyItem] = [] { didSet { persist() } }
    @Published var tools: [Tool] = [] { didSet { persist() } }

    // MARK: - Lifecycle

    init() {
        load()
        isReady = true
    }

    // MARK: - Persistence

    private func persist() {
        guard isReady else { return }
        save()
    }

    func save() {
        let snap = StoreSnapshot(
            projectName: projectName, goal: goal, startDate: startDate,
            rooms: rooms, measurements: measurements, materials: materials,
            quotes: quotes, issues: issues, photoNotes: photoNotes,
            documents: documents, milestones: milestones,
            qualityCriteria: qualityCriteria, punchItems: punchItems,
            estimateLines: estimateLines, budgetLimits: budgetLimits,
            stages: stages, tasks: tasks, crew: crew,
            safetyItems: safetyItems, tools: tools)
        if let data = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let snap = try? JSONDecoder().decode(StoreSnapshot.self, from: data) else {
            return
        }
        projectName = snap.projectName
        goal = snap.goal
        startDate = snap.startDate
        rooms = snap.rooms
        measurements = snap.measurements
        materials = snap.materials
        quotes = snap.quotes
        issues = snap.issues
        photoNotes = snap.photoNotes
        documents = snap.documents
        milestones = snap.milestones
        qualityCriteria = snap.qualityCriteria
        punchItems = snap.punchItems
        estimateLines = snap.estimateLines
        budgetLimits = snap.budgetLimits
        stages = snap.stages
        tasks = snap.tasks
        crew = snap.crew
        safetyItems = snap.safetyItems
        tools = snap.tools
    }

    var hasData: Bool { !rooms.isEmpty || !tasks.isEmpty }

    /// Wipe everything and reseed the rich sample project (used by Settings).
    func resetSampleData() {
        SampleData.populate(self)
    }

    func clearAll() {
        isReady = false
        rooms = []; measurements = []; materials = []; quotes = []
        issues = []; photoNotes = []; documents = []; milestones = []
        qualityCriteria = []; punchItems = []; estimateLines = []
        budgetLimits = []; stages = []; tasks = []; crew = []
        safetyItems = []; tools = []
        isReady = true
        save()
    }

    // MARK: - Lookups

    func room(_ id: UUID?) -> Room? {
        guard let id = id else { return nil }
        return rooms.first { $0.id == id }
    }
    func roomName(_ id: UUID?) -> String { room(id)?.name ?? "Unassigned" }

    func stage(_ id: UUID?) -> WorkStage? {
        guard let id = id else { return nil }
        return stages.first { $0.id == id }
    }

    // MARK: - Progress analytics

    /// Completion of a room based on its tasks, falling back to its status.
    func progress(forRoom id: UUID) -> Double {
        let roomTasks = tasks.filter { $0.roomID == id }
        if roomTasks.isEmpty {
            return room(id)?.status.fraction ?? 0
        }
        let done = roomTasks.filter { $0.state == .done }.count
        return Double(done) / Double(roomTasks.count)
    }

    var overallProgress: Double {
        if !stages.isEmpty {
            let total = stages.reduce(0.0) { $0 + $1.status.fraction }
            return total / Double(stages.count)
        }
        guard !rooms.isEmpty else { return 0 }
        return rooms.reduce(0.0) { $0 + progress(forRoom: $1.id) } / Double(rooms.count)
    }

    // MARK: - Cost analytics

    func estimateTotal(forRoom id: UUID?) -> Double {
        estimateLines.filter { $0.roomID == id }.reduce(0) { $0 + $1.total }
    }
    func materialsTotal(forRoom id: UUID?) -> Double {
        materials.filter { $0.roomID == id }.reduce(0) { $0 + $1.lineTotal }
    }
    /// Total planned cost for a room: estimate lines + material list.
    func plannedCost(forRoom id: UUID) -> Double {
        estimateTotal(forRoom: id) + materialsTotal(forRoom: id)
    }
    /// Money committed (ordered/delivered) for a room.
    func committedCost(forRoom id: UUID) -> Double {
        materials.filter { $0.roomID == id && $0.status != .needed }
            .reduce(0) { $0 + $1.lineTotal }
    }

    var estimateGrandTotal: Double { estimateLines.reduce(0) { $0 + $1.total } }
    var materialsGrandTotal: Double { materials.reduce(0) { $0 + $1.lineTotal } }
    var plannedTotal: Double { estimateGrandTotal + materialsGrandTotal }
    var committedSpend: Double {
        materials.filter { $0.status != .needed }.reduce(0) { $0 + $1.lineTotal }
    }

    func limit(forRoom id: UUID) -> Double {
        budgetLimits.first { $0.roomID == id }?.limit ?? 0
    }
    func setLimit(_ value: Double, forRoom id: UUID) {
        if let i = budgetLimits.firstIndex(where: { $0.roomID == id }) {
            budgetLimits[i].limit = value
        } else {
            budgetLimits.append(BudgetLimit(roomID: id, limit: value))
        }
    }

    // MARK: - Risks & upcoming actions

    var risks: [RiskItem] {
        var items: [RiskItem] = []
        for issue in issues where !issue.resolved && issue.severity == .high {
            items.append(RiskItem(title: issue.title, detail: "High-severity issue",
                                  icon: "exclamationmark.triangle.fill", tint: Theme.danger))
        }
        for task in tasks where task.state == .blocked {
            items.append(RiskItem(title: task.title, detail: "Blocked task",
                                  icon: "exclamationmark.octagon.fill", tint: Theme.danger))
        }
        for safety in safetyItems where safety.flagged {
            items.append(RiskItem(title: safety.title, detail: "Safety hazard flag",
                                  icon: "shield.lefthalf.fill", tint: Theme.warning))
        }
        for doc in documents where doc.isExpired {
            items.append(RiskItem(title: doc.name, detail: "Document expired",
                                  icon: "doc.badge.ellipsis", tint: Theme.warning))
        }
        let now = Date()
        for ms in milestones where !ms.done && ms.date < now {
            items.append(RiskItem(title: ms.title, detail: "Milestone overdue",
                                  icon: "calendar.badge.exclamationmark", tint: Theme.danger))
        }
        return items
    }
    var riskCount: Int { risks.count }

    var upcoming: [UpcomingItem] {
        var items: [UpcomingItem] = []
        for task in tasks where task.state != .done {
            items.append(UpcomingItem(title: task.title,
                                      subtitle: roomName(task.roomID),
                                      date: task.dueDate,
                                      icon: task.state.icon, tint: task.state.tint))
        }
        for ms in milestones where !ms.done {
            items.append(UpcomingItem(title: ms.title, subtitle: "Milestone",
                                      date: ms.date,
                                      icon: "flag.fill", tint: Theme.purple))
        }
        return items.sorted { $0.date < $1.date }
    }

    var projectedFinish: Date {
        milestones.map { $0.date }.max()
            ?? tasks.map { $0.dueDate }.max()
            ?? Calendar.current.date(byAdding: .day, value: 30, to: startDate) ?? startDate
    }

    // MARK: - Counters used in summaries

    var openIssueCount: Int { issues.filter { !$0.resolved }.count }
    var openPunchCount: Int { punchItems.filter { !$0.closed }.count }
    var doneTaskCount: Int { tasks.filter { $0.state == .done }.count }
    var totalArea: Double { rooms.reduce(0) { $0 + $1.plannedArea } }
}
