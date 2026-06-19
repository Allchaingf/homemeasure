//
//  PlanningViewModels.swift
//  HomeMeasure
//
//  View models for cost & schedule planning: Estimate, Budget, Timeline,
//  Work Stages, Task Board and Crew Planner.
//

import SwiftUI

// MARK: - Estimate Builder (Screen 16)

final class EstimateViewModel: StoreViewModel {
    @Published var name = ""
    @Published var category: EstimateCategory = .material
    @Published var quantity: Double = 1
    @Published var unitPrice: Double = 0
    @Published var roomID: UUID? = nil
    @Published var wastePercent: Double = 8
    @Published var deliveryCost: Double = 0

    var canAdd: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    func subtotal() -> Double { store?.estimateGrandTotal ?? 0 }
    func wasteAmount() -> Double { subtotal() * wastePercent / 100 }
    func grandTotal() -> Double { subtotal() + wasteAmount() + deliveryCost }

    func addLine() {
        guard let store = store, canAdd else { warn("Enter a line name"); return }
        store.estimateLines.append(EstimateLine(name: name, category: category,
                                                quantity: quantity, unitPrice: unitPrice, roomID: roomID))
        confirm("Line added")
        name = ""; quantity = 1; unitPrice = 0
    }

    func delete(_ line: EstimateLine) {
        store?.estimateLines.removeAll { $0.id == line.id }
    }

    func saveEstimate() {
        store?.save()
        confirm("Estimate saved · \(settings?.money(grandTotal()) ?? "")")
    }
}

// MARK: - Budget by Room (Screen 17)

final class BudgetViewModel: StoreViewModel {
    @Published var selectedRoomID: UUID? = nil
    @Published var limitValue: Double = 0

    func selectRoom(_ id: UUID) {
        selectedRoomID = id
        limitValue = store?.limit(forRoom: id) ?? 0
    }

    func setLimit() {
        guard let store = store, let id = selectedRoomID else { warn("Pick a room"); return }
        store.setLimit(limitValue, forRoom: id)
        confirm("Limit set · \(settings?.money(limitValue) ?? "")")
    }

    func actual(_ id: UUID) -> Double { store?.plannedCost(forRoom: id) ?? 0 }
    func limit(_ id: UUID) -> Double { store?.limit(forRoom: id) ?? 0 }
    func isOver(_ id: UUID) -> Bool {
        let l = limit(id)
        return l > 0 && actual(id) > l
    }
    func ratio(_ id: UUID) -> Double {
        let l = limit(id)
        return l > 0 ? min(1.2, actual(id) / l) : 0
    }
}

// MARK: - Timeline Calendar (Screen 6)

final class TimelineViewModel: StoreViewModel {
    @Published var title = ""
    @Published var date = Date()
    @Published var shiftDays = 0

    var canAdd: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    func addMilestone() {
        guard let store = store, canAdd else { warn("Enter a milestone title"); return }
        store.milestones.append(Milestone(title: title, date: date, done: false))
        confirm("Milestone added")
        title = ""
    }

    func toggleDone(_ m: Milestone) {
        guard let store = store, let i = store.milestones.firstIndex(where: { $0.id == m.id }) else { return }
        store.milestones[i].done.toggle()
    }

    func shiftAll() {
        guard let store = store, shiftDays != 0 else { warn("Choose a number of days"); return }
        let cal = Calendar.current
        for i in store.milestones.indices where !store.milestones[i].done {
            store.milestones[i].date = cal.date(byAdding: .day, value: shiftDays, to: store.milestones[i].date) ?? store.milestones[i].date
        }
        for i in store.tasks.indices where store.tasks[i].state != .done {
            store.tasks[i].dueDate = cal.date(byAdding: .day, value: shiftDays, to: store.tasks[i].dueDate) ?? store.tasks[i].dueDate
        }
        confirm("Shifted \(shiftDays > 0 ? "+" : "")\(shiftDays) days")
        shiftDays = 0
    }

    func delete(_ m: Milestone) {
        store?.milestones.removeAll { $0.id == m.id }
    }
}

// MARK: - Work Stages (Screen 18)

final class WorkStageViewModel: StoreViewModel {
    @Published var name = ""
    @Published var phase: StagePhase = .preparation

    var canAdd: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    func addStage() {
        guard let store = store, canAdd else { warn("Enter a stage name"); return }
        let order = (store.stages.map { $0.order }.max() ?? -1) + 1
        store.stages.append(WorkStage(name: name, phase: phase, status: .notStarted, order: order))
        confirm("Stage added")
        name = ""
    }

    func moveNext(_ stage: WorkStage) {
        guard let store = store, let i = store.stages.firstIndex(where: { $0.id == stage.id }) else { return }
        let order: [BuildStatus] = [.notStarted, .inProgress, .done]
        if let idx = order.firstIndex(of: store.stages[i].status) {
            store.stages[i].status = order[(idx + 1) % order.count]
            confirm("\(stage.name): \(store.stages[i].status.title)")
        }
    }

    func delete(_ stage: WorkStage) {
        store?.stages.removeAll { $0.id == stage.id }
    }
}

// MARK: - Task Board (Screen 19)

final class TaskBoardViewModel: StoreViewModel {
    @Published var title = ""
    @Published var roomID: UUID? = nil
    @Published var stageID: UUID? = nil
    @Published var assignee = ""
    @Published var dueDate = Date()

    var canAdd: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    func tasks(in state: TaskState) -> [ProjectTask] {
        (store?.tasks ?? []).filter { $0.state == state }
    }

    func addTask() {
        guard let store = store, canAdd else { warn("Enter a task title"); return }
        store.tasks.append(ProjectTask(title: title, state: .planned, roomID: roomID,
                                       stageID: stageID, assignee: assignee, dueDate: dueDate))
        confirm("Task created")
        title = ""; assignee = ""
    }

    func move(_ task: ProjectTask, to state: TaskState) {
        guard let store = store, let i = store.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        store.tasks[i].state = state
    }

    func setDueDate(_ date: Date, for task: ProjectTask) {
        guard let store = store, let i = store.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        store.tasks[i].dueDate = date
        confirm("Due date updated")
    }

    func delete(_ task: ProjectTask) {
        store?.tasks.removeAll { $0.id == task.id }
    }
}

// MARK: - Crew Planner (Screen 20)

final class CrewViewModel: StoreViewModel {
    @Published var name = ""
    @Published var role: CrewRole = .helper
    @Published var note = ""

    var canAdd: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    func addMember() {
        guard let store = store, canAdd else { warn("Enter a name"); return }
        store.crew.append(CrewMember(name: name, role: role, note: note))
        confirm("Assignment added")
        name = ""; note = ""
    }

    func setRole(_ role: CrewRole, for member: CrewMember) {
        guard let store = store, let i = store.crew.firstIndex(where: { $0.id == member.id }) else { return }
        store.crew[i].role = role
        confirm("\(member.name): \(role.title)")
    }

    func assign(_ task: ProjectTask, to member: CrewMember) {
        guard let store = store, let i = store.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        store.tasks[i].assignee = member.name
        confirm("Assigned \(task.title) → \(member.name)")
    }

    func unassignedTasks() -> [ProjectTask] {
        (store?.tasks ?? []).filter { $0.state != .done }
    }

    func delete(_ member: CrewMember) {
        store?.crew.removeAll { $0.id == member.id }
    }
}
