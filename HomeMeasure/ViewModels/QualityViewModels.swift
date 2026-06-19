//
//  QualityViewModels.swift
//  HomeMeasure
//
//  View models for issues, quality, punch list, safety, tools, photo markup
//  and supplier quotes.
//

import SwiftUI

// MARK: - Issue Log (Screen 3)

final class IssueViewModel: StoreViewModel {
    @Published var title = ""
    @Published var severity: Severity = .medium
    @Published var roomID: UUID? = nil
    @Published var note = ""

    var canAdd: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    func addIssue() {
        guard let store = store, canAdd else { warn("Enter an issue title"); return }
        store.issues.append(Issue(title: title, severity: severity, resolved: false,
                                  roomID: roomID, note: note, date: Date()))
        confirm("Issue logged")
        title = ""; note = ""
    }

    func resolve(_ issue: Issue) {
        guard let store = store, let i = store.issues.firstIndex(where: { $0.id == issue.id }) else { return }
        store.issues[i].resolved.toggle()
        confirm(store.issues[i].resolved ? "Issue resolved" : "Issue reopened")
    }

    func delete(_ issue: Issue) {
        store?.issues.removeAll { $0.id == issue.id }
    }
}

// MARK: - Quality Check (Screen 7)

final class QualityViewModel: StoreViewModel {
    @Published var title = ""
    @Published var roomID: UUID? = nil
    @Published var reviewSummary: String? = nil

    var canAdd: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    func addCriterion() {
        guard let store = store, canAdd else { warn("Enter a criterion"); return }
        store.qualityCriteria.append(QualityCriterion(title: title, roomID: roomID))
        confirm("Criterion added")
        title = ""
    }

    func togglePass(_ c: QualityCriterion) {
        guard let store = store, let i = store.qualityCriteria.firstIndex(where: { $0.id == c.id }) else { return }
        store.qualityCriteria[i].passed.toggle()
        if store.qualityCriteria[i].passed && store.qualityCriteria[i].rating == 0 {
            store.qualityCriteria[i].rating = 4
        }
    }

    func setRating(_ rating: Int, for c: QualityCriterion) {
        guard let store = store, let i = store.qualityCriteria.firstIndex(where: { $0.id == c.id }) else { return }
        store.qualityCriteria[i].rating = rating
    }

    func setEvidence(_ text: String, for c: QualityCriterion) {
        guard let store = store, let i = store.qualityCriteria.firstIndex(where: { $0.id == c.id }) else { return }
        store.qualityCriteria[i].evidence = text
        confirm("Evidence added")
    }

    func runReview() {
        guard let store = store, !store.qualityCriteria.isEmpty else { warn("No criteria yet"); return }
        let passed = store.qualityCriteria.filter { $0.passed }.count
        let total = store.qualityCriteria.count
        reviewSummary = "\(passed)/\(total) criteria passed"
        confirm(reviewSummary!)
    }

    func delete(_ c: QualityCriterion) {
        store?.qualityCriteria.removeAll { $0.id == c.id }
    }
}

// MARK: - Punch List (Screen 8)

final class PunchListViewModel: StoreViewModel {
    @Published var title = ""
    @Published var roomID: UUID? = nil

    var canAdd: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    func addItem() {
        guard let store = store, canAdd else { warn("Enter a punch item"); return }
        store.punchItems.append(PunchItem(title: title, roomID: roomID))
        confirm("Punch item added")
        title = ""
    }

    func toggleClosed(_ item: PunchItem) {
        guard let store = store, let i = store.punchItems.firstIndex(where: { $0.id == item.id }) else { return }
        store.punchItems[i].closed.toggle()
        confirm(store.punchItems[i].closed ? "Marked closed" : "Reopened")
    }

    func delete(_ item: PunchItem) {
        store?.punchItems.removeAll { $0.id == item.id }
    }
}

// MARK: - Safety Checklist (Screen 21)

final class SafetyViewModel: StoreViewModel {
    @Published var newTitle = ""
    @Published var newCategory: SafetyCategory = .electrical

    func toggleCheck(_ item: SafetyItem) {
        guard let store = store, let i = store.safetyItems.firstIndex(where: { $0.id == item.id }) else { return }
        store.safetyItems[i].checked.toggle()
    }

    func toggleFlag(_ item: SafetyItem) {
        guard let store = store, let i = store.safetyItems.firstIndex(where: { $0.id == item.id }) else { return }
        store.safetyItems[i].flagged.toggle()
        confirm(store.safetyItems[i].flagged ? "Hazard flagged → Risk Center" : "Flag cleared",
                icon: "shield.lefthalf.fill",
                color: store.safetyItems[i].flagged ? Theme.danger : Theme.success)
    }

    func runCheck() {
        guard let store = store, !store.safetyItems.isEmpty else { warn("No checklist items"); return }
        let ok = store.safetyItems.filter { $0.checked }.count
        let flags = store.safetyItems.filter { $0.flagged }.count
        confirm("\(ok)/\(store.safetyItems.count) checked · \(flags) hazard\(flags == 1 ? "" : "s")")
    }

    func addItem() {
        guard let store = store, !newTitle.trimmingCharacters(in: .whitespaces).isEmpty else { warn("Enter a check"); return }
        store.safetyItems.append(SafetyItem(title: newTitle, category: newCategory))
        confirm("Check added")
        newTitle = ""
    }

    func delete(_ item: SafetyItem) {
        store?.safetyItems.removeAll { $0.id == item.id }
    }
}

// MARK: - Tool Inventory (Screen 22)

final class ToolViewModel: StoreViewModel {
    @Published var name = ""
    @Published var status: ToolStatus = .available
    @Published var isRental = false
    @Published var note = ""

    var canAdd: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    func add() {
        guard let store = store, canAdd else { warn("Enter a tool name"); return }
        store.tools.append(Tool(name: name, status: status, isRental: isRental, note: note))
        confirm("Tool added")
        name = ""; note = ""; isRental = false
    }

    func cycleStatus(_ tool: Tool) {
        guard let store = store, let i = store.tools.firstIndex(where: { $0.id == tool.id }) else { return }
        let order: [ToolStatus] = [.available, .needed, .missing]
        if let idx = order.firstIndex(of: store.tools[i].status) {
            store.tools[i].status = order[(idx + 1) % order.count]
            confirm("\(tool.name): \(store.tools[i].status.title)")
        }
    }

    func delete(_ tool: Tool) {
        store?.tools.removeAll { $0.id == tool.id }
    }
}

// MARK: - Photo Markup (Screen 4)

final class PhotoMarkupViewModel: StoreViewModel {
    @Published var title = ""
    @Published var roomID: UUID? = nil
    @Published var problem = ""
    @Published var markerX: Double = 0.5
    @Published var markerY: Double = 0.5
    @Published var backdropIndex = 0

    // Offline "site photo" placeholders rendered from gradients (no camera roll).
    let backdrops: [[String]] = [
        ["3A5F7D", "1E3A52"], ["6D5D4B", "3C3327"], ["4B6D5D", "27392F"], ["5D4B6D", "342740"]
    ]

    var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    func cyclePhoto() {
        backdropIndex = (backdropIndex + 1) % backdrops.count
        confirm("Photo \(backdropIndex + 1) attached", icon: "photo")
    }

    func markProblem() {
        guard let store = store, canSave else { warn("Add a title first"); return }
        store.photoNotes.append(PhotoNote(title: title, roomID: roomID,
                                          markerX: markerX, markerY: markerY,
                                          problem: problem, linkedToPunch: false))
        confirm("Problem marked & saved")
        title = ""; problem = ""; markerX = 0.5; markerY = 0.5
    }

    func sendToPunch(_ note: PhotoNote) {
        guard let store = store else { return }
        store.punchItems.append(PunchItem(title: note.title, roomID: note.roomID, note: note.problem))
        if let i = store.photoNotes.firstIndex(where: { $0.id == note.id }) {
            store.photoNotes[i].linkedToPunch = true
        }
        confirm("Added to punch list")
    }

    func delete(_ note: PhotoNote) {
        store?.photoNotes.removeAll { $0.id == note.id }
    }
}

// MARK: - Supplier Compare (Screen 2)

final class QuoteCompareViewModel: StoreViewModel {
    @Published var supplier = ""
    @Published var price: Double = 0
    @Published var leadDays: Double = 7
    @Published var deliveryNote = ""
    @Published var notes = ""

    var canAdd: Bool { !supplier.trimmingCharacters(in: .whitespaces).isEmpty }

    func addQuote() {
        guard let store = store, canAdd else { warn("Enter a supplier"); return }
        store.quotes.append(Quote(supplier: supplier, price: price, leadDays: Int(leadDays),
                                  deliveryNote: deliveryNote, notes: notes, isChosen: false))
        confirm("Quote added")
        supplier = ""; price = 0; leadDays = 7; deliveryNote = ""; notes = ""
    }

    /// Picks the lowest-priced quote as the chosen one and logs the decision.
    func chooseBest() {
        guard let store = store, !store.quotes.isEmpty else { warn("Add quotes first"); return }
        guard let best = store.quotes.min(by: { $0.price < $1.price }) else { return }
        for i in store.quotes.indices { store.quotes[i].isChosen = (store.quotes[i].id == best.id) }
        confirm("Chose \(best.supplier) · \(settings?.money(best.price) ?? "")")
    }

    func choose(_ quote: Quote) {
        guard let store = store else { return }
        for i in store.quotes.indices { store.quotes[i].isChosen = (store.quotes[i].id == quote.id) }
        confirm("Chose \(quote.supplier)")
    }

    func delete(_ quote: Quote) {
        store?.quotes.removeAll { $0.id == quote.id }
    }
}
