//
//  Models.swift
//  HomeMeasure
//
//  Codable value types for every entity in a renovation project.
//  All are Identifiable + Equatable so SwiftUI lists diff cleanly.
//

import Foundation

// MARK: - Room / work area

struct Room: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var type: AreaType = .room
    var plannedArea: Double = 0          // in current unit, m² or ft²
    var status: BuildStatus = .notStarted
    var priority: Priority = .medium
    var colorHex: String = "2E8BE6"
    var scope: String = ""
    var targetDate: Date = Date()
}

// MARK: - Measurement

struct Measurement: Identifiable, Codable, Equatable {
    var id = UUID()
    var roomID: UUID?
    var label: String
    var kind: MeasureKind = .area
    var length: Double = 0
    var width: Double = 0
    var height: Double = 0
    var wastePercent: Double = 10

    /// Raw geometric result before waste, in the current unit.
    var baseResult: Double {
        switch kind {
        case .area: return length * width
        case .linear: return length
        case .volume: return length * width * height
        }
    }
    /// Result including a material waste allowance.
    var resultWithWaste: Double { baseResult * (1 + wastePercent / 100) }
    var unitLabel: String {
        switch kind {
        case .area: return "area"
        case .linear: return "length"
        case .volume: return "volume"
        }
    }
}

// MARK: - Material

struct Material: Identifiable, Codable, Equatable {
    var id = UUID()
    var roomID: UUID?
    var name: String
    var quantity: Double = 1
    var unit: String = "pcs"
    var unitPrice: Double = 0
    var status: MaterialStatus = .needed
    var purchasedQuantity: Double = 0

    var lineTotal: Double { quantity * unitPrice }
    var remaining: Double { max(0, quantity - purchasedQuantity) }
}

// MARK: - Supplier quote

struct Quote: Identifiable, Codable, Equatable {
    var id = UUID()
    var supplier: String
    var price: Double = 0
    var leadDays: Int = 7
    var deliveryNote: String = ""
    var notes: String = ""
    var isChosen: Bool = false
}

// MARK: - Issue / blocker

struct Issue: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var severity: Severity = .medium
    var resolved: Bool = false
    var roomID: UUID?
    var note: String = ""
    var date: Date = Date()
}

// MARK: - Photo markup note

struct PhotoNote: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var roomID: UUID?
    var markerX: Double = 0.5        // normalized 0...1 within the canvas
    var markerY: Double = 0.5
    var problem: String = ""
    var linkedToPunch: Bool = false
}

// MARK: - Document / permit

struct ProjectDocument: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var type: DocType = .permit
    var issued: Date = Date()
    var expiry: Date = Date()
    var notes: String = ""

    var isExpired: Bool { expiry < Date() }
    var daysToExpiry: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: expiry).day ?? 0
    }
}

// MARK: - Milestone (timeline)

struct Milestone: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var date: Date = Date()
    var done: Bool = false
}

// MARK: - Quality criterion

struct QualityCriterion: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var roomID: UUID?
    var passed: Bool = false
    var rating: Int = 0              // 0...5
    var evidence: String = ""
}

// MARK: - Punch list item

struct PunchItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var roomID: UUID?
    var closed: Bool = false
    var note: String = ""
}

// MARK: - Estimate line

struct EstimateLine: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var category: EstimateCategory = .material
    var quantity: Double = 1
    var unitPrice: Double = 0
    var roomID: UUID?

    var total: Double { quantity * unitPrice }
}

// MARK: - Budget limit (per room / stage)

struct BudgetLimit: Identifiable, Codable, Equatable {
    var id = UUID()
    var roomID: UUID
    var limit: Double = 0
}

// MARK: - Work stage

struct WorkStage: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var phase: StagePhase = .preparation
    var status: BuildStatus = .notStarted
    var order: Int = 0
}

// MARK: - Task

struct ProjectTask: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var state: TaskState = .planned
    var roomID: UUID?
    var stageID: UUID?
    var assignee: String = ""
    var dueDate: Date = Date()
}

// MARK: - Crew member

struct CrewMember: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var role: CrewRole = .helper
    var note: String = ""
}

// MARK: - Safety check item

struct SafetyItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var category: SafetyCategory = .electrical
    var checked: Bool = false
    var flagged: Bool = false
}

// MARK: - Tool / equipment

struct Tool: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var status: ToolStatus = .available
    var isRental: Bool = false
    var note: String = ""
}
