//
//  SampleData.swift
//  HomeMeasure
//
//  Builds a realistic starter project so every dashboard, chart and report
//  has meaningful content on first launch. Re-runnable from Settings.
//

import Foundation

enum SampleData {

    private static func day(_ offset: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
    }

    static func populate(_ store: ProjectStore) {
        store.clearAll()

        // Meta -----------------------------------------------------------
        store.projectName = "Maple Street Reno"
        store.goal = .rebuild
        store.startDate = day(-24)

        // Rooms ----------------------------------------------------------
        let kitchen = Room(name: "Kitchen", type: .room, plannedArea: 14.5,
                           status: .inProgress, priority: .high, colorHex: "FF7A1A",
                           scope: "Full gut & rebuild", targetDate: day(18))
        let living = Room(name: "Living Room", type: .room, plannedArea: 22.0,
                          status: .inProgress, priority: .medium, colorHex: "2E8BE6",
                          scope: "Refinish floor, repaint", targetDate: day(26))
        let bath = Room(name: "Master Bath", type: .room, plannedArea: 7.2,
                        status: .notStarted, priority: .high, colorHex: "16C0C8",
                        scope: "Re-tile, new fixtures", targetDate: day(34))
        let bedroom = Room(name: "Bedroom", type: .room, plannedArea: 16.0,
                           status: .notStarted, priority: .low, colorHex: "8A6CF0",
                           scope: "Paint & flooring", targetDate: day(40))
        let facade = Room(name: "Front Facade", type: .exterior, plannedArea: 38.0,
                          status: .blocked, priority: .medium, colorHex: "29C281",
                          scope: "Render & paint", targetDate: day(50))
        store.rooms = [kitchen, living, bath, bedroom, facade]

        // Measurements ---------------------------------------------------
        store.measurements = [
            Measurement(roomID: kitchen.id, label: "Floor area", kind: .area,
                        length: 4.2, width: 3.45, wastePercent: 10),
            Measurement(roomID: kitchen.id, label: "Backsplash", kind: .area,
                        length: 3.2, width: 0.6, wastePercent: 15),
            Measurement(roomID: living.id, label: "Floor area", kind: .area,
                        length: 5.5, width: 4.0, wastePercent: 8),
            Measurement(roomID: bath.id, label: "Wall tile", kind: .area,
                        length: 9.0, width: 2.4, wastePercent: 12),
            Measurement(roomID: living.id, label: "Skirting", kind: .linear,
                        length: 19.0, wastePercent: 10)
        ]

        // Materials ------------------------------------------------------
        store.materials = [
            Material(roomID: kitchen.id, name: "Floor tiles", quantity: 16, unit: "m²",
                     unitPrice: 28, status: .delivered, purchasedQuantity: 16),
            Material(roomID: kitchen.id, name: "Cabinet set", quantity: 1, unit: "set",
                     unitPrice: 2400, status: .ordered, purchasedQuantity: 1),
            Material(roomID: bath.id, name: "Wall tiles", quantity: 24, unit: "m²",
                     unitPrice: 34, status: .needed, purchasedQuantity: 0),
            Material(roomID: living.id, name: "Engineered wood", quantity: 24, unit: "m²",
                     unitPrice: 45, status: .needed, purchasedQuantity: 0),
            Material(roomID: facade.id, name: "Exterior render", quantity: 6, unit: "bag",
                     unitPrice: 22, status: .ordered, purchasedQuantity: 4),
            Material(roomID: kitchen.id, name: "Paint (interior)", quantity: 12, unit: "L",
                     unitPrice: 9, status: .delivered, purchasedQuantity: 12)
        ]

        // Quotes ---------------------------------------------------------
        store.quotes = [
            Quote(supplier: "TileWorld", price: 1850, leadDays: 5,
                  deliveryNote: "Free over $1500", notes: "Good range", isChosen: true),
            Quote(supplier: "BuildMart", price: 1720, leadDays: 12,
                  deliveryNote: "$60 delivery", notes: "Cheapest but slow"),
            Quote(supplier: "ProSupply", price: 1990, leadDays: 3,
                  deliveryNote: "Next-day", notes: "Fast, premium")
        ]

        // Issues ---------------------------------------------------------
        store.issues = [
            Issue(title: "Leaking pipe behind wall", severity: .high, resolved: false,
                  roomID: bath.id, note: "Found during demo", date: day(-3)),
            Issue(title: "Tile delivery delayed", severity: .medium, resolved: false,
                  roomID: kitchen.id, note: "ETA +1 week", date: day(-1)),
            Issue(title: "Uneven subfloor", severity: .low, resolved: true,
                  roomID: living.id, note: "Self-leveled", date: day(-8))
        ]

        // Photo notes ----------------------------------------------------
        store.photoNotes = [
            PhotoNote(title: "Crack near window", roomID: living.id,
                      markerX: 0.62, markerY: 0.38, problem: "Plaster crack to patch", linkedToPunch: true),
            PhotoNote(title: "Pipe junction", roomID: bath.id,
                      markerX: 0.3, markerY: 0.7, problem: "Replace fitting")
        ]

        // Documents ------------------------------------------------------
        store.documents = [
            ProjectDocument(name: "Building permit", type: .permit,
                            issued: day(-30), expiry: day(60), notes: "City council"),
            ProjectDocument(name: "Electrical cert", type: .inspection,
                            issued: day(-20), expiry: day(-2), notes: "Needs renewal"),
            ProjectDocument(name: "Appliance warranty", type: .warranty,
                            issued: day(-15), expiry: day(700), notes: "")
        ]

        // Milestones -----------------------------------------------------
        store.milestones = [
            Milestone(title: "Demolition complete", date: day(-10), done: true),
            Milestone(title: "Rough-in done", date: day(6), done: false),
            Milestone(title: "Tiling complete", date: day(20), done: false),
            Milestone(title: "Final handover", date: day(52), done: false)
        ]

        // Quality criteria -----------------------------------------------
        store.qualityCriteria = [
            QualityCriterion(title: "Floor level within 3mm", roomID: kitchen.id,
                             passed: true, rating: 5, evidence: "Laser checked"),
            QualityCriterion(title: "Grout lines even", roomID: bath.id,
                             passed: false, rating: 2, evidence: ""),
            QualityCriterion(title: "Paint coverage complete", roomID: living.id,
                             passed: true, rating: 4, evidence: "2 coats")
        ]

        // Punch list -----------------------------------------------------
        store.punchItems = [
            PunchItem(title: "Touch up door frame paint", roomID: living.id, closed: false),
            PunchItem(title: "Caulk around sink", roomID: kitchen.id, closed: false),
            PunchItem(title: "Adjust cabinet hinge", roomID: kitchen.id, closed: true)
        ]

        // Stages ---------------------------------------------------------
        let s1 = WorkStage(name: "Site prep & demo", phase: .preparation, status: .done, order: 0)
        let s2 = WorkStage(name: "Rough plumbing & electric", phase: .rough, status: .inProgress, order: 1)
        let s3 = WorkStage(name: "Finishes & tiling", phase: .finish, status: .notStarted, order: 2)
        let s4 = WorkStage(name: "Final verification", phase: .verify, status: .notStarted, order: 3)
        store.stages = [s1, s2, s3, s4]

        // Estimate lines -------------------------------------------------
        store.estimateLines = [
            EstimateLine(name: "Kitchen labor", category: .labor, quantity: 40, unitPrice: 45, roomID: kitchen.id),
            EstimateLine(name: "Cabinets", category: .material, quantity: 1, unitPrice: 2400, roomID: kitchen.id),
            EstimateLine(name: "Bathroom labor", category: .labor, quantity: 28, unitPrice: 45, roomID: bath.id),
            EstimateLine(name: "Tile + grout", category: .material, quantity: 24, unitPrice: 34, roomID: bath.id),
            EstimateLine(name: "Living floor install", category: .labor, quantity: 16, unitPrice: 40, roomID: living.id),
            EstimateLine(name: "Scaffold rental", category: .equipment, quantity: 1, unitPrice: 320, roomID: facade.id)
        ]

        // Budget limits --------------------------------------------------
        store.budgetLimits = [
            BudgetLimit(roomID: kitchen.id, limit: 6500),
            BudgetLimit(roomID: bath.id, limit: 3200),
            BudgetLimit(roomID: living.id, limit: 2800),
            BudgetLimit(roomID: facade.id, limit: 1500)
        ]

        // Tasks ----------------------------------------------------------
        store.tasks = [
            ProjectTask(title: "Demo old cabinets", state: .done, roomID: kitchen.id, stageID: s1.id, assignee: "Mike", dueDate: day(-9)),
            ProjectTask(title: "Run new wiring", state: .active, roomID: kitchen.id, stageID: s2.id, assignee: "Elena", dueDate: day(3)),
            ProjectTask(title: "Fix leaking pipe", state: .blocked, roomID: bath.id, stageID: s2.id, assignee: "Mike", dueDate: day(2)),
            ProjectTask(title: "Order bathroom tiles", state: .planned, roomID: bath.id, stageID: s3.id, assignee: "You", dueDate: day(5)),
            ProjectTask(title: "Sand living room floor", state: .planned, roomID: living.id, stageID: s3.id, assignee: "Helper", dueDate: day(12)),
            ProjectTask(title: "Render front wall", state: .blocked, roomID: facade.id, stageID: s2.id, assignee: "Contractor", dueDate: day(8)),
            ProjectTask(title: "Final walkthrough", state: .planned, roomID: nil, stageID: s4.id, assignee: "You", dueDate: day(50))
        ]

        // Crew -----------------------------------------------------------
        store.crew = [
            CrewMember(name: "You", role: .owner, note: "Project lead"),
            CrewMember(name: "Mike", role: .contractor, note: "General builder"),
            CrewMember(name: "Elena", role: .contractor, note: "Electrician"),
            CrewMember(name: "Helper", role: .helper, note: "On-call labor")
        ]

        // Safety ---------------------------------------------------------
        store.safetyItems = [
            SafetyItem(title: "Power isolated before wiring", category: .electrical, checked: true, flagged: false),
            SafetyItem(title: "Ladder footing stable", category: .ladders, checked: true, flagged: false),
            SafetyItem(title: "Dust extraction running", category: .dust, checked: false, flagged: true),
            SafetyItem(title: "Tools inspected", category: .tools, checked: true, flagged: false),
            SafetyItem(title: "Site access clear", category: .access, checked: false, flagged: false)
        ]

        // Tools ----------------------------------------------------------
        store.tools = [
            Tool(name: "Cordless drill", status: .available, isRental: false, note: "2 batteries"),
            Tool(name: "Tile saw", status: .needed, isRental: true, note: "Rent for bath"),
            Tool(name: "Laser level", status: .available, isRental: false, note: ""),
            Tool(name: "Scaffold tower", status: .missing, isRental: true, note: "Order this week")
        ]

        store.save()
    }
}
