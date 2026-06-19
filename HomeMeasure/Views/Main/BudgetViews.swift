//
//  BudgetViews.swift
//  HomeMeasure
//
//  Screen 16 — Estimate Builder, Screen 15 — Material List,
//  Screen 17 — Budget by Room, Screen 10 — Cost Trends.
//

import SwiftUI

// MARK: - Estimate Builder (Screen 16)

struct EstimateBuilderView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var toast: ToastCenter
    @StateObject private var vm = EstimateViewModel()
    @State private var showForm = false

    var body: some View {
        ScreenScaffold {
            quickLinks
            totals
            HStack(spacing: 12) {
                PrimaryButton(title: "Add Line", systemImage: "plus") { showForm = true }
                SecondaryButton(title: "Save Estimate", systemImage: "tray.and.arrow.down", tint: Theme.teal) {
                    vm.saveEstimate()
                }
            }
            lines
        }
        .navigationBarTitle("Estimate Builder", displayMode: .inline)
        .onAppear { vm.configure(store, settings, toast) }
        .sheet(isPresented: $showForm) { form }
    }

    private var quickLinks: some View {
        HStack(spacing: 12) {
            navTile("Materials", "shippingbox.fill", Theme.accent, MaterialListView())
            navTile("By Room", "chart.pie.fill", Theme.blue, BudgetSplitView())
            navTile("Trends", "chart.line.uptrend.xyaxis", Theme.teal, CostAnalyticsView())
        }
    }

    private func navTile<D: View>(_ title: String, _ icon: String, _ tint: Color, _ dest: D) -> some View {
        NavigationLink(destination: dest) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 18, weight: .bold)).foregroundColor(tint)
                Text(title).font(.appCaption(12)).foregroundColor(Theme.textPrimary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: Metrics.radius).fill(Theme.surface))
            .overlay(RoundedRectangle(cornerRadius: Metrics.radius).stroke(Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var totals: some View {
        Card {
            VStack(spacing: 12) {
                row("Subtotal", settings.money(vm.subtotal()))
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Waste").font(.appBody(14)).foregroundColor(Theme.textSecondary)
                        Spacer()
                        Text("\(Int(vm.wastePercent))%  ·  \(settings.money(vm.wasteAmount()))")
                            .font(.appCaption(12)).foregroundColor(Theme.textSecondary)
                    }
                    Slider(value: $vm.wastePercent, in: 0...25, step: 1).accentColor(Theme.accent)
                }
                AppNumberField(title: "Delivery / logistics", value: $vm.deliveryCost,
                               suffix: settings.currencySymbol, systemImage: "shippingbox.fill")
                Divider().background(Theme.stroke)
                HStack {
                    Text("Forecast total").font(.appHeadline(16)).foregroundColor(Theme.textPrimary)
                    Spacer()
                    Text(settings.money(vm.grandTotal())).font(.appNumber(22)).foregroundColor(Theme.accent)
                }
            }
        }
    }

    private func row(_ a: String, _ b: String) -> some View {
        HStack {
            Text(a).font(.appBody(14)).foregroundColor(Theme.textSecondary)
            Spacer()
            Text(b).font(.appHeadline(15)).foregroundColor(Theme.textPrimary)
        }
    }

    private var lines: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Estimate lines", subtitle: "\(store.estimateLines.count) items", systemImage: "list.bullet.indent")
                if store.estimateLines.isEmpty {
                    Text("No lines yet.").font(.appBody(14)).foregroundColor(Theme.textMuted)
                } else {
                    ForEach(store.estimateLines) { line in
                        HStack(spacing: 10) {
                            Circle().fill(line.category.tint).frame(width: 10, height: 10)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(line.name).font(.appBody(15)).foregroundColor(Theme.textPrimary)
                                Text("\(settings.formatNumber(line.quantity)) × \(settings.money(line.unitPrice)) · \(store.roomName(line.roomID))")
                                    .font(.appCaption(11)).foregroundColor(Theme.textMuted)
                            }
                            Spacer()
                            Text(settings.money(line.total)).font(.appHeadline(15)).foregroundColor(Theme.textPrimary)
                            Button(action: { vm.delete(line) }) {
                                Image(systemName: "trash").font(.system(size: 13)).foregroundColor(Theme.danger)
                            }
                        }
                        if line.id != store.estimateLines.last?.id { Divider().background(Theme.stroke) }
                    }
                }
            }
        }
    }

    private var form: some View {
        FormSheet(title: "Add Line", saveTitle: "Add", canSave: vm.canAdd,
                  onSave: { vm.addLine(); showForm = false }, onCancel: { showForm = false }) {
            AppTextField(title: "Line name", text: $vm.name, placeholder: "e.g. Tiling labor", systemImage: "tag")
            labeled("Category") { EnumChips(selection: $vm.category, title: { $0.title }, tint: Theme.accent) }
            HStack(spacing: 12) {
                AppNumberField(title: "Quantity", value: $vm.quantity, systemImage: "number")
                AppNumberField(title: "Unit price", value: $vm.unitPrice, suffix: settings.currencySymbol, systemImage: "dollarsign")
            }
            labeled("Room") { RoomChips(rooms: store.rooms, selection: $vm.roomID) }
        }
    }

    private func labeled<C: View>(_ t: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(t.uppercased()).font(.appCaption(11)).foregroundColor(Theme.textMuted)
            content()
        }
    }
}

// MARK: - Material List (Screen 15)

struct MaterialListView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var toast: ToastCenter
    @StateObject private var vm = MaterialViewModel()
    @State private var showForm = false

    var body: some View {
        ScreenScaffold {
            Card {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Materials value").font(.appCaption(12)).foregroundColor(Theme.textMuted)
                        Text(settings.money(store.materialsGrandTotal)).font(.appNumber(22)).foregroundColor(Theme.accent)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Committed").font(.appCaption(12)).foregroundColor(Theme.textMuted)
                        Text(settings.money(store.committedSpend)).font(.appHeadline(17)).foregroundColor(Theme.success)
                    }
                }
            }
            HStack(spacing: 12) {
                PrimaryButton(title: "Add Material", systemImage: "plus") { showForm = true }
                SecondaryButton(title: "Mark Ordered", systemImage: "shippingbox", tint: Theme.blue) { vm.markAllOrdered() }
            }
            if store.materials.isEmpty {
                Card { EmptyStateView(systemImage: "shippingbox", title: "No materials", message: "Add materials to track quantities, cost and purchase status.") }
            } else {
                ForEach(store.materials) { m in materialRow(m) }
            }
        }
        .navigationBarTitle("Materials", displayMode: .inline)
        .onAppear { vm.configure(store, settings, toast) }
        .sheet(isPresented: $showForm) { form }
    }

    private func materialRow(_ m: Material) -> some View {
        Card {
            HStack(spacing: 12) {
                Image(systemName: m.status.icon).font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white).frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 10).fill(m.status.tint))
                VStack(alignment: .leading, spacing: 3) {
                    Text(m.name).font(.appHeadline(16)).foregroundColor(Theme.textPrimary)
                    Text("\(settings.formatNumber(m.quantity)) \(m.unit) · \(settings.money(m.unitPrice))/ea · \(store.roomName(m.roomID))")
                        .font(.appCaption(11)).foregroundColor(Theme.textMuted).lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text(settings.money(m.lineTotal)).font(.appHeadline(15)).foregroundColor(Theme.textPrimary)
                    Button(action: { vm.markOrdered(m) }) {
                        Chip(text: m.status.title, color: m.status.tint, filled: true)
                    }
                }
            }
            .contextMenu {
                Button(action: { vm.delete(m) }) { Label("Delete", systemImage: "trash").foregroundColor(Theme.danger) }
            }
        }
    }

    private var form: some View {
        FormSheet(title: "Add Material", saveTitle: "Add", canSave: vm.canAdd,
                  onSave: { vm.add(); showForm = false }, onCancel: { showForm = false }) {
            AppTextField(title: "Material", text: $vm.name, placeholder: "e.g. Floor tiles", systemImage: "shippingbox")
            HStack(spacing: 12) {
                AppNumberField(title: "Quantity", value: $vm.quantity, systemImage: "number")
                AppNumberField(title: "Unit price", value: $vm.unitPrice, suffix: settings.currencySymbol, systemImage: "dollarsign")
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("UNIT").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(vm.units, id: \.self) { u in
                            SelectableChip(text: u, isSelected: vm.unit == u, color: Theme.teal) { vm.unit = u }
                        }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("ROOM").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                RoomChips(rooms: store.rooms, selection: $vm.roomID)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("STATUS").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                EnumChips(selection: $vm.status, title: { $0.title }, tint: Theme.blue)
            }
        }
    }
}

// MARK: - Budget by Room (Screen 17)

struct BudgetSplitView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var toast: ToastCenter
    @StateObject private var vm = BudgetViewModel()
    @State private var compare = false

    var body: some View {
        ScreenScaffold {
            setLimitCard
            HStack(spacing: 12) {
                PrimaryButton(title: "Set Limit", systemImage: "slider.horizontal.3") { vm.setLimit() }
                SecondaryButton(title: compare ? "Hide Compare" : "Compare", systemImage: "chart.bar.xaxis", tint: Theme.blue) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { compare.toggle() }
                }
            }
            if compare { compareCard }
            roomsBudget
        }
        .navigationBarTitle("Budget by Room", displayMode: .inline)
        .onAppear { vm.configure(store, settings, toast) }
    }

    private var setLimitCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Set a room limit", systemImage: "target")
                RoomChips(rooms: store.rooms, selection: Binding(
                    get: { vm.selectedRoomID },
                    set: { if let id = $0 { vm.selectRoom(id) } else { vm.selectedRoomID = nil } }), includeNone: false)
                AppNumberField(title: "Limit", value: $vm.limitValue, suffix: settings.currencySymbol, systemImage: "dollarsign.circle")
                if let id = vm.selectedRoomID {
                    HStack {
                        Text("Current actual").font(.appCaption(12)).foregroundColor(Theme.textMuted)
                        Spacer()
                        Text(settings.money(vm.actual(id))).font(.appCaption(13)).foregroundColor(Theme.textPrimary)
                    }
                }
            }
        }
    }

    private var compareCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Limit vs actual", systemImage: "chart.bar.xaxis")
                HBarChart(data: store.rooms.map { room in
                    let limit = vm.limit(room.id)
                    let actual = vm.actual(room.id)
                    let base = max(limit, actual, 1)
                    return BarDatum(label: room.name, value: actual,
                                    tint: vm.isOver(room.id) ? Theme.danger : Theme.success,
                                    caption: "\(Int(actual / base * 100))%")
                })
            }
        }
    }

    private var roomsBudget: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Per-room budgets", systemImage: "chart.pie.fill")
                if store.rooms.isEmpty {
                    Text("No rooms yet.").font(.appBody(14)).foregroundColor(Theme.textMuted)
                }
                ForEach(store.rooms) { room in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(room.name).font(.appBody(15)).foregroundColor(Theme.textPrimary)
                            Spacer()
                            if vm.limit(room.id) > 0 {
                                Text("\(settings.money(vm.actual(room.id))) / \(settings.money(vm.limit(room.id)))")
                                    .font(.appCaption(12))
                                    .foregroundColor(vm.isOver(room.id) ? Theme.danger : Theme.textSecondary)
                            } else {
                                Text("No limit").font(.appCaption(12)).foregroundColor(Theme.textMuted)
                            }
                        }
                        ProgressBar(value: vm.ratio(room.id),
                                    tint: vm.isOver(room.id) ? Theme.danger : Color(hex: room.colorHex))
                        if vm.isOver(room.id) {
                            Text("Over budget by \(settings.money(vm.actual(room.id) - vm.limit(room.id)))")
                                .font(.appCaption(11)).foregroundColor(Theme.danger)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Cost Analytics (Screen 10)

struct CostAnalyticsView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var toast: ToastCenter
    @StateObject private var vm = CostAnalyticsViewModel()

    var body: some View {
        ScreenScaffold {
            summary
            HStack(spacing: 12) {
                PrimaryButton(title: vm.showVariance ? "Hide Variance" : "View Variance", systemImage: "arrow.up.arrow.down") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { vm.showVariance.toggle() }
                }
            }
            if vm.showVariance { variance }
            categories
            expensive
        }
        .navigationBarTitle("Cost Trends", displayMode: .inline)
        .onAppear { vm.configure(store, settings, toast) }
    }

    private var summary: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            StatTile(title: "Planned", value: settings.money(vm.planned), systemImage: "doc.text", tint: Theme.blue)
            StatTile(title: "Committed", value: settings.money(vm.committed), systemImage: "creditcard", tint: Theme.accent)
            StatTile(title: "Materials", value: settings.money(store.materialsGrandTotal), systemImage: "shippingbox", tint: Theme.teal)
            StatTile(title: "Variance", value: settings.money(vm.variance),
                     systemImage: "arrow.up.arrow.down", tint: vm.variance > 0 ? Theme.danger : Theme.success)
        }
    }

    private var variance: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Budget variance", subtitle: "Over (red) / under (green) limit", systemImage: "arrow.up.arrow.down")
                let bars = vm.varianceBars()
                if bars.isEmpty {
                    Text("Set room limits to see variance.").font(.appBody(14)).foregroundColor(Theme.textMuted)
                } else {
                    HBarChart(data: bars)
                }
            }
        }
    }

    private var categories: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "By category", systemImage: "square.grid.2x2")
                ForEach(EstimateCategory.allCases) { cat in
                    HStack {
                        Circle().fill(cat.tint).frame(width: 10, height: 10)
                        Text(cat.title).font(.appBody(14)).foregroundColor(Theme.textPrimary)
                        Spacer()
                        Text(settings.money(vm.categoryTotal(cat))).font(.appHeadline(15)).foregroundColor(Theme.textPrimary)
                    }
                }
            }
        }
    }

    private var expensive: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Most expensive rooms", systemImage: "flame.fill")
                let bars = vm.roomCostBars()
                if bars.isEmpty {
                    Text("No room costs yet.").font(.appBody(14)).foregroundColor(Theme.textMuted)
                } else {
                    HBarChart(data: bars)
                }
            }
        }
    }
}
