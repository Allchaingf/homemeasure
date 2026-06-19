//
//  CoreViewModels.swift
//  HomeMeasure
//
//  View models for the core CRUD screens: Dashboard, Rooms, Project Intake,
//  Measurements and Materials.
//

import SwiftUI

// MARK: - Dashboard

final class DashboardViewModel: StoreViewModel {
    @Published var quickTask = ""
    @Published var dueDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
    @Published var roomID: UUID? = nil

    var canAdd: Bool { !quickTask.trimmingCharacters(in: .whitespaces).isEmpty }

    func addQuickTask() {
        guard let store = store, canAdd else { warn("Enter a task title"); return }
        store.tasks.append(ProjectTask(title: quickTask.trimmingCharacters(in: .whitespaces),
                                       state: .planned, roomID: roomID, dueDate: dueDate))
        quickTask = ""
        roomID = nil
        confirm("Task added")
    }
}

// MARK: - Room Builder (Screen 13)

final class RoomBuilderViewModel: StoreViewModel {
    @Published var name = ""
    @Published var type: AreaType = .room
    @Published var area: Double = 0
    @Published var priority: Priority = .medium
    @Published var colorHex = "2E8BE6"
    @Published var scope = ""
    @Published var targetDate = Date()
    @Published var editingID: UUID? = nil

    let palette = ["FF7A1A", "2E8BE6", "16C0C8", "8A6CF0", "29C281", "F5455C", "F7B500"]

    var isEditing: Bool { editingID != nil }
    var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    func reset() {
        name = ""; type = .room; area = 0; priority = .medium
        colorHex = "2E8BE6"; scope = ""; targetDate = Date(); editingID = nil
    }

    func load(_ room: Room) {
        name = room.name; type = room.type; area = room.plannedArea
        priority = room.priority; colorHex = room.colorHex
        scope = room.scope; targetDate = room.targetDate; editingID = room.id
    }

    func save() {
        guard let store = store, canSave else { warn("Name is required"); return }
        if let id = editingID, let i = store.rooms.firstIndex(where: { $0.id == id }) {
            store.rooms[i].name = name
            store.rooms[i].type = type
            store.rooms[i].plannedArea = area
            store.rooms[i].priority = priority
            store.rooms[i].colorHex = colorHex
            store.rooms[i].scope = scope
            store.rooms[i].targetDate = targetDate
            confirm("Room updated")
        } else {
            store.rooms.append(Room(name: name, type: type, plannedArea: area,
                                    status: .notStarted, priority: priority,
                                    colorHex: colorHex, scope: scope, targetDate: targetDate))
            confirm("Room created")
        }
        reset()
    }

    func delete(_ room: Room) {
        store?.rooms.removeAll { $0.id == room.id }
        // Clean up dependent records.
        store?.measurements.removeAll { $0.roomID == room.id }
        confirm("Room deleted", icon: "trash", color: Theme.danger)
    }

    func setStatus(_ status: BuildStatus, for room: Room) {
        guard let store = store, let i = store.rooms.firstIndex(where: { $0.id == room.id }) else { return }
        store.rooms[i].status = status
    }
}

// MARK: - Project Intake (Screen 12)

final class IntakeViewModel: StoreViewModel {
    @Published var name = ""
    @Published var type: AreaType = .room
    @Published var scope = ""
    @Published var area: Double = 0
    @Published var priority: Priority = .medium

    var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    private func build() -> Room {
        Room(name: name, type: type, plannedArea: area, status: .notStarted,
             priority: priority, colorHex: "2E8BE6", scope: scope, targetDate: Date())
    }

    func reset() { name = ""; type = .room; scope = ""; area = 0; priority = .medium }

    /// Adds the area and signals the caller to dismiss.
    func addArea() -> Bool {
        guard let store = store, canSave else { warn("Enter an area name"); return false }
        store.rooms.append(build())
        confirm("Work area added")
        reset()
        return true
    }

    /// Saves the scope and stays so the user can add another.
    func saveScope() {
        guard let store = store, canSave else { warn("Enter an area name"); return }
        store.rooms.append(build())
        confirm("Scope saved")
        reset()
    }
}

// MARK: - Measurement Pad (Screen 14)

final class MeasurementViewModel: StoreViewModel {
    @Published var label = ""
    @Published var roomID: UUID? = nil
    @Published var kind: MeasureKind = .area
    @Published var length: Double = 0
    @Published var width: Double = 0
    @Published var height: Double = 0
    @Published var waste: Double = 10
    @Published var lastResult: Double? = nil

    var preview: Measurement {
        Measurement(roomID: roomID, label: label, kind: kind,
                    length: length, width: width, height: height, wastePercent: waste)
    }

    func calculate() {
        lastResult = preview.resultWithWaste
        UISelectionFeedbackGenerator().selectionChanged()
    }

    func add() {
        guard let store = store else { return }
        guard !label.trimmingCharacters(in: .whitespaces).isEmpty else { warn("Add a label"); return }
        guard preview.baseResult > 0 else { warn("Enter dimensions"); return }
        store.measurements.append(preview)
        confirm("Measurement saved")
        label = ""; length = 0; width = 0; height = 0; lastResult = nil
    }

    func delete(_ m: Measurement) {
        store?.measurements.removeAll { $0.id == m.id }
    }
}

// MARK: - Material List (Screen 15)

final class MaterialViewModel: StoreViewModel {
    @Published var name = ""
    @Published var roomID: UUID? = nil
    @Published var quantity: Double = 1
    @Published var unit = "pcs"
    @Published var unitPrice: Double = 0
    @Published var status: MaterialStatus = .needed

    let units = ["pcs", "m²", "m", "L", "kg", "bag", "box", "set"]

    var canAdd: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    func add() {
        guard let store = store, canAdd else { warn("Enter a material name"); return }
        store.materials.append(Material(roomID: roomID, name: name, quantity: quantity,
                                        unit: unit, unitPrice: unitPrice, status: status,
                                        purchasedQuantity: status == .delivered ? quantity : 0))
        confirm("Material added")
        name = ""; quantity = 1; unitPrice = 0; status = .needed
    }

    func markOrdered(_ m: Material) {
        guard let store = store, let i = store.materials.firstIndex(where: { $0.id == m.id }) else { return }
        let next: MaterialStatus = m.status == .needed ? .ordered : (m.status == .ordered ? .delivered : .needed)
        store.materials[i].status = next
        if next == .delivered { store.materials[i].purchasedQuantity = store.materials[i].quantity }
        confirm("\(m.name): \(next.title)")
    }

    func markAllOrdered() {
        guard let store = store else { return }
        let needed = store.materials.filter { $0.status == .needed }.count
        guard needed > 0 else { warn("Nothing left to order"); return }
        for i in store.materials.indices where store.materials[i].status == .needed {
            store.materials[i].status = .ordered
        }
        confirm("\(needed) material\(needed == 1 ? "" : "s") marked ordered")
    }

    func delete(_ m: Material) {
        store?.materials.removeAll { $0.id == m.id }
    }
}
