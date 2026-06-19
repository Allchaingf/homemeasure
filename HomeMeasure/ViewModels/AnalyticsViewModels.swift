//
//  AnalyticsViewModels.swift
//  HomeMeasure
//
//  View models for analytics and reporting: Progress Trends, Cost Trends,
//  Report Builder (with real PDF export) and the Permit/Document tracker.
//

import SwiftUI

struct BarDatum: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let tint: Color
    var caption: String = ""
}

// MARK: - Progress Analytics (Screen 9)

final class ProgressAnalyticsViewModel: StoreViewModel {
    @Published var phaseFilter: StagePhase? = nil
    @Published var compareMode = false

    func roomBars() -> [BarDatum] {
        guard let store = store else { return [] }
        return store.rooms.map { room in
            BarDatum(label: room.name, value: store.progress(forRoom: room.id),
                     tint: Color(hex: room.colorHex),
                     caption: "\(Int(store.progress(forRoom: room.id) * 100))%")
        }
    }

    func stageBars() -> [BarDatum] {
        guard let store = store else { return [] }
        let stages = phaseFilter == nil ? store.stages : store.stages.filter { $0.phase == phaseFilter }
        return stages.sorted { $0.order < $1.order }.map { stage in
            BarDatum(label: stage.name, value: stage.status.fraction, tint: stage.status.tint,
                     caption: stage.status.title)
        }
    }

    /// Tasks completed grouped into simple weekly buckets relative to start.
    func weeklyCompletion() -> [BarDatum] {
        guard let store = store else { return [] }
        let cal = Calendar.current
        var buckets = [Int: Int]()
        for task in store.tasks where task.state == .done {
            let weeks = (cal.dateComponents([.weekOfYear], from: store.startDate, to: task.dueDate).weekOfYear ?? 0)
            buckets[max(0, weeks), default: 0] += 1
        }
        let maxWeek = max(buckets.keys.max() ?? 0, 3)
        return (0...maxWeek).map { w in
            BarDatum(label: "W\(w + 1)", value: Double(buckets[w] ?? 0),
                     tint: Theme.blue, caption: "\(buckets[w] ?? 0)")
        }
    }

    var stalled: [String] {
        guard let store = store else { return [] }
        return store.rooms.filter { store.progress(forRoom: $0.id) < 0.25 }.map { $0.name }
    }
}

// MARK: - Cost Analytics (Screen 10)

final class CostAnalyticsViewModel: StoreViewModel {
    @Published var categoryFilter: EstimateCategory? = nil
    @Published var showVariance = false

    func roomCostBars() -> [BarDatum] {
        guard let store = store else { return [] }
        let bars = store.rooms.map { room -> BarDatum in
            let planned = store.plannedCost(forRoom: room.id)
            return BarDatum(label: room.name, value: planned, tint: Color(hex: room.colorHex),
                            caption: settings?.money(planned) ?? "")
        }
        return bars.sorted { $0.value > $1.value }
    }

    func varianceBars() -> [BarDatum] {
        guard let store = store else { return [] }
        return store.rooms.compactMap { room in
            let limit = store.limit(forRoom: room.id)
            guard limit > 0 else { return nil }
            let actual = store.plannedCost(forRoom: room.id)
            let variance = actual - limit
            return BarDatum(label: room.name, value: abs(variance),
                            tint: variance > 0 ? Theme.danger : Theme.success,
                            caption: (variance > 0 ? "+" : "") + (settings?.money(variance) ?? ""))
        }
    }

    func categoryTotal(_ cat: EstimateCategory) -> Double {
        (store?.estimateLines ?? []).filter { $0.category == cat }.reduce(0) { $0 + $1.total }
    }

    var planned: Double { store?.plannedTotal ?? 0 }
    var committed: Double { store?.committedSpend ?? 0 }
    var variance: Double { committed - planned }
}

// MARK: - Report Builder (Screen 11)

final class ReportViewModel: StoreViewModel {
    @Published var includeProgress = true
    @Published var includeBudget = true
    @Published var includeRisks = true
    @Published var includeTasks = true
    @Published var reportText: String = ""
    @Published var pdfURL: URL? = nil
    @Published var showShare = false

    private func df() -> DateFormatter {
        let f = DateFormatter(); f.dateStyle = .medium; return f
    }

    func generate() {
        guard let store = store, let settings = settings else { return }
        var lines: [String] = []
        lines.append("HOMEMEASURE PROJECT REPORT")
        lines.append("Project: \(store.projectName)")
        lines.append("Goal: \(store.goal.title)   Started: \(df().string(from: store.startDate))")
        lines.append("Projected finish: \(df().string(from: store.projectedFinish))")
        lines.append(String(repeating: "─", count: 34))

        if includeProgress {
            lines.append("\nPROGRESS")
            lines.append("Overall: \(Int(store.overallProgress * 100))%")
            for room in store.rooms {
                lines.append("  • \(room.name): \(Int(store.progress(forRoom: room.id) * 100))% (\(room.status.title))")
            }
        }
        if includeBudget {
            lines.append("\nBUDGET")
            lines.append("Planned total: \(settings.money(store.plannedTotal))")
            lines.append("Committed spend: \(settings.money(store.committedSpend))")
            lines.append("Materials list: \(settings.money(store.materialsGrandTotal))")
        }
        if includeRisks {
            lines.append("\nRISKS (\(store.riskCount))")
            if store.risks.isEmpty { lines.append("  • None flagged") }
            for r in store.risks { lines.append("  • \(r.title) — \(r.detail)") }
        }
        if includeTasks {
            lines.append("\nTASKS")
            lines.append("Done: \(store.doneTaskCount)/\(store.tasks.count)")
            for t in store.tasks.filter({ $0.state != .done }).prefix(12) {
                lines.append("  • [\(t.state.title)] \(t.title) — \(df().string(from: t.dueDate))")
            }
        }
        lines.append("\nOpen issues: \(store.openIssueCount)   Open punch items: \(store.openPunchCount)")
        reportText = lines.joined(separator: "\n")
        confirm("Report generated")
    }

    /// Renders the generated report into a PDF file and triggers a share sheet.
    func exportPDF() {
        if reportText.isEmpty { generate() }
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 @72dpi
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor.black
            ]
            let inset = CGRect(x: 36, y: 36, width: pageRect.width - 72, height: pageRect.height - 72)
            (reportText as NSString).draw(in: inset, withAttributes: attrs)
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("HomeMeasure-Report.pdf")
        do {
            try data.write(to: url)
            pdfURL = url
            showShare = true
            confirm("PDF ready to export")
        } catch {
            warn("Could not create PDF")
        }
    }
}

// MARK: - Permit Tracker (Screen 5)

final class PermitViewModel: StoreViewModel {
    @Published var name = ""
    @Published var type: DocType = .permit
    @Published var issued = Date()
    @Published var expiry = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @Published var notes = ""

    var canAdd: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    func add() {
        guard let store = store, canAdd else { warn("Enter a document name"); return }
        store.documents.append(ProjectDocument(name: name, type: type, issued: issued,
                                               expiry: expiry, notes: notes))
        confirm("Document added")
        name = ""; notes = ""
    }

    func setExpiry(_ date: Date, for doc: ProjectDocument) {
        guard let store = store, let i = store.documents.firstIndex(where: { $0.id == doc.id }) else { return }
        store.documents[i].expiry = date
        confirm("Expiry updated")
    }

    func delete(_ doc: ProjectDocument) {
        store?.documents.removeAll { $0.id == doc.id }
    }
}
