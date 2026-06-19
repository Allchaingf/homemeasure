//
//  Enums.swift
//  HomeMeasure
//
//  All domain enumerations with display helpers (title, icon, color).
//

import SwiftUI

// MARK: - Onboarding choices

enum HomeGoal: String, Codable, CaseIterable, Identifiable {
    case fix, refresh, rebuild, inspect
    var id: String { rawValue }
    var title: String {
        switch self {
        case .fix: return "Fix"
        case .refresh: return "Refresh"
        case .rebuild: return "Rebuild"
        case .inspect: return "Inspect"
        }
    }
    var subtitle: String {
        switch self {
        case .fix: return "Repair what's broken"
        case .refresh: return "Cosmetic update"
        case .rebuild: return "Full renovation"
        case .inspect: return "Assess & document"
        }
    }
    var icon: String {
        switch self {
        case .fix: return "wrench.and.screwdriver.fill"
        case .refresh: return "paintbrush.fill"
        case .rebuild: return "hammer.fill"
        case .inspect: return "magnifyingglass"
        }
    }
    var tint: Color {
        switch self {
        case .fix: return Theme.warning
        case .refresh: return Theme.teal
        case .rebuild: return Theme.accent
        case .inspect: return Theme.blue
        }
    }
}

enum DetailLevel: String, Codable, CaseIterable, Identifiable {
    case light, standard, pro
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var blurb: String {
        switch self {
        case .light: return "Just the essentials — rooms, budget, tasks."
        case .standard: return "Balanced detail with analytics and quality."
        case .pro: return "Every tool: safety, crew, reports, variance."
        }
    }
    var icon: String {
        switch self {
        case .light: return "sun.min.fill"
        case .standard: return "gauge"
        case .pro: return "gauge.badge.plus"
        }
    }
}

// MARK: - Units / currency

enum UnitSystem: String, Codable, CaseIterable, Identifiable {
    case metric, imperial
    var id: String { rawValue }
    var title: String { self == .metric ? "Metric (m, m²)" : "Imperial (ft, ft²)" }
    var lengthUnit: String { self == .metric ? "m" : "ft" }
    var areaUnit: String { self == .metric ? "m²" : "ft²" }
}

// MARK: - Rooms / areas

enum AreaType: String, Codable, CaseIterable, Identifiable {
    case room, wall, floor, exterior, utility
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .room: return "square.split.bottomrightquarter.fill"
        case .wall: return "rectangle.portrait.fill"
        case .floor: return "square.grid.3x3.fill"
        case .exterior: return "house.fill"
        case .utility: return "bolt.fill"
        }
    }
}

enum Priority: String, Codable, CaseIterable, Identifiable {
    case low, medium, high
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var tint: Color {
        switch self {
        case .low: return Theme.info
        case .medium: return Theme.warning
        case .high: return Theme.danger
        }
    }
}

/// Generic completion status used by rooms and stages.
enum BuildStatus: String, Codable, CaseIterable, Identifiable {
    case notStarted, inProgress, blocked, done
    var id: String { rawValue }
    var title: String {
        switch self {
        case .notStarted: return "Not Started"
        case .inProgress: return "In Progress"
        case .blocked: return "Blocked"
        case .done: return "Done"
        }
    }
    var tint: Color {
        switch self {
        case .notStarted: return Theme.textMuted
        case .inProgress: return Theme.blue
        case .blocked: return Theme.danger
        case .done: return Theme.success
        }
    }
    var fraction: Double {
        switch self {
        case .notStarted: return 0
        case .inProgress: return 0.5
        case .blocked: return 0.35
        case .done: return 1
        }
    }
}

// MARK: - Measurements

enum MeasureKind: String, Codable, CaseIterable, Identifiable {
    case area, linear, volume
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .area: return "square.dashed"
        case .linear: return "ruler"
        case .volume: return "cube"
        }
    }
}

// MARK: - Materials

enum MaterialStatus: String, Codable, CaseIterable, Identifiable {
    case needed, ordered, delivered
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var tint: Color {
        switch self {
        case .needed: return Theme.warning
        case .ordered: return Theme.blue
        case .delivered: return Theme.success
        }
    }
    var icon: String {
        switch self {
        case .needed: return "cart.badge.plus"
        case .ordered: return "shippingbox"
        case .delivered: return "checkmark.seal.fill"
        }
    }
}

// MARK: - Issues

enum Severity: String, Codable, CaseIterable, Identifiable {
    case low, medium, high
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var tint: Color {
        switch self {
        case .low: return Theme.info
        case .medium: return Theme.warning
        case .high: return Theme.danger
        }
    }
}

// MARK: - Documents / permits

enum DocType: String, Codable, CaseIterable, Identifiable {
    case permit, warranty, contract, inspection, insurance
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .permit: return "doc.text.fill"
        case .warranty: return "checkmark.shield"
        case .contract: return "signature"
        case .inspection: return "list.bullet"
        case .insurance: return "umbrella"
        }
    }
}

// MARK: - Stages

enum StagePhase: String, Codable, CaseIterable, Identifiable {
    case preparation, rough, finish, verify
    var id: String { rawValue }
    var title: String {
        switch self {
        case .preparation: return "Preparation"
        case .rough: return "Rough Work"
        case .finish: return "Finish"
        case .verify: return "Verify"
        }
    }
    var icon: String {
        switch self {
        case .preparation: return "shippingbox.fill"
        case .rough: return "hammer"
        case .finish: return "paintbrush.pointed.fill"
        case .verify: return "checkmark.circle"
        }
    }
    var order: Int {
        switch self {
        case .preparation: return 0
        case .rough: return 1
        case .finish: return 2
        case .verify: return 3
        }
    }
}

// MARK: - Tasks

enum TaskState: String, Codable, CaseIterable, Identifiable {
    case planned, active, blocked, done
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var tint: Color {
        switch self {
        case .planned: return Theme.textMuted
        case .active: return Theme.blue
        case .blocked: return Theme.danger
        case .done: return Theme.success
        }
    }
    var icon: String {
        switch self {
        case .planned: return "circle"
        case .active: return "play.circle.fill"
        case .blocked: return "exclamationmark.octagon.fill"
        case .done: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Crew

enum CrewRole: String, Codable, CaseIterable, Identifiable {
    case owner, contractor, helper
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var tint: Color {
        switch self {
        case .owner: return Theme.accent
        case .contractor: return Theme.blue
        case .helper: return Theme.teal
        }
    }
    var icon: String {
        switch self {
        case .owner: return "person.crop.circle.badge.plus"
        case .contractor: return "person.2.fill"
        case .helper: return "hands.sparkles.fill"
        }
    }
}

// MARK: - Safety

enum SafetyCategory: String, Codable, CaseIterable, Identifiable {
    case electrical, ladders, dust, tools, access
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .electrical: return "bolt.fill"
        case .ladders: return "arrow.up.and.down"
        case .dust: return "wind"
        case .tools: return "wrench.and.screwdriver.fill"
        case .access: return "lock.open.fill"
        }
    }
}

// MARK: - Tools

enum ToolStatus: String, Codable, CaseIterable, Identifiable {
    case available, needed, missing
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var tint: Color {
        switch self {
        case .available: return Theme.success
        case .needed: return Theme.warning
        case .missing: return Theme.danger
        }
    }
}

// MARK: - Estimate

enum EstimateCategory: String, Codable, CaseIterable, Identifiable {
    case labor, material, equipment, other
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var tint: Color {
        switch self {
        case .labor: return Theme.blue
        case .material: return Theme.accent
        case .equipment: return Theme.purple
        case .other: return Theme.teal
        }
    }
}

// MARK: - Theme mode

enum ThemeMode: String, Codable, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .system: return "iphone"
        case .light: return "sun.max.fill"
        case .dark: return "moon.stars.fill"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
