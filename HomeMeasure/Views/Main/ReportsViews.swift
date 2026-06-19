//
//  ReportsViews.swift
//  HomeMeasure
//
//  Screen 11 — Report Builder (with real PDF export), Screen 5 — Permit
//  Tracker, Screen 2 — Supplier / Quote Compare.
//

import SwiftUI

// MARK: - Report Builder (Screen 11)

struct ReportBuilderView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var toast: ToastCenter
    @StateObject private var vm = ReportViewModel()

    var body: some View {
        ScreenScaffold {
            Card {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Sections to include", systemImage: "doc.text.fill")
                    toggle("Progress", $vm.includeProgress, "chart.line.uptrend.xyaxis")
                    toggle("Budget", $vm.includeBudget, "dollarsign.circle")
                    toggle("Risks", $vm.includeRisks, "exclamationmark.triangle")
                    toggle("Tasks", $vm.includeTasks, "list.bullet")
                }
            }
            HStack(spacing: 12) {
                PrimaryButton(title: "Generate Report", systemImage: "doc.text.fill") { vm.generate() }
                SecondaryButton(title: "Export PDF", systemImage: "square.and.arrow.up", tint: Theme.blue) { vm.exportPDF() }
            }
            if !vm.reportText.isEmpty {
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Preview", systemImage: "eye")
                        Text(vm.reportText)
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundColor(Theme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else {
                Card { EmptyStateView(systemImage: "doc.text.magnifyingglass", title: "No report yet",
                                      message: "Pick sections, then tap Generate Report to build a shareable summary.") }
            }
        }
        .navigationBarTitle("Build Report", displayMode: .inline)
        .onAppear { vm.configure(store, settings, toast) }
        .sheet(isPresented: $vm.showShare) {
            if let url = vm.pdfURL { ShareSheet(items: [url]) }
        }
    }

    private func toggle(_ title: String, _ binding: Binding<Bool>, _ icon: String) -> some View {
        Toggle(isOn: binding) {
            Label(title, systemImage: icon).font(.appBody(15)).foregroundColor(Theme.textPrimary)
        }
        .toggleStyle(SwitchToggleStyle(tint: Theme.accent))
    }
}

// MARK: - Permit Tracker (Screen 5)

struct PermitTrackerView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var toast: ToastCenter
    @StateObject private var vm = PermitViewModel()
    @State private var showAdd = false
    @State private var expiryTarget: ProjectDocument? = nil

    var body: some View {
        ScreenScaffold {
            HStack(spacing: 12) {
                PrimaryButton(title: "Add Document", systemImage: "plus") { showAdd = true }
                SecondaryButton(title: "Set Expiry", systemImage: "calendar.badge.clock", tint: Theme.blue) {
                    expiryTarget = store.documents.first
                    if expiryTarget == nil { vm.warn("No documents yet") }
                }
            }
            if store.documents.isEmpty {
                Card { EmptyStateView(systemImage: "doc.text.fill", title: "No documents",
                                      message: "Track permits, warranties and certificates — stored locally only.") }
            } else {
                ForEach(store.documents) { doc in docRow(doc) }
            }
        }
        .navigationBarTitle("Documents & Permits", displayMode: .inline)
        .onAppear { vm.configure(store, settings, toast) }
        .sheet(isPresented: $showAdd) { addSheet }
        .sheet(item: $expiryTarget) { doc in expirySheet(doc) }
    }

    private func docRow(_ doc: ProjectDocument) -> some View {
        Card {
            HStack(spacing: 12) {
                Image(systemName: doc.type.icon).font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white).frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 10).fill(doc.isExpired ? Theme.danger : Theme.blue))
                VStack(alignment: .leading, spacing: 3) {
                    Text(doc.name).font(.appHeadline(15)).foregroundColor(Theme.textPrimary)
                    Text("\(doc.type.title) · expires \(DateFmt.string(doc.expiry))")
                        .font(.appCaption(11)).foregroundColor(Theme.textMuted)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    if doc.isExpired { Chip(text: "Expired", color: Theme.danger, filled: true) }
                    else { Chip(text: "\(doc.daysToExpiry)d left", color: doc.daysToExpiry < 14 ? Theme.warning : Theme.success) }
                    HStack(spacing: 8) {
                        Button(action: { expiryTarget = doc }) {
                            Image(systemName: "calendar.badge.clock").foregroundColor(Theme.accent)
                        }
                        Button(action: { vm.delete(doc) }) {
                            Image(systemName: "trash").font(.system(size: 13)).foregroundColor(Theme.danger)
                        }
                    }
                }
            }
        }
    }

    private var addSheet: some View {
        FormSheet(title: "Add Document", saveTitle: "Add", canSave: vm.canAdd,
                  onSave: { vm.add(); showAdd = false }, onCancel: { showAdd = false }) {
            AppTextField(title: "Document name", text: $vm.name, placeholder: "e.g. Building permit", systemImage: "doc")
            VStack(alignment: .leading, spacing: 6) {
                Text("TYPE").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                EnumChips(selection: $vm.type, title: { $0.title }, tint: Theme.blue, icon: { $0.icon })
            }
            datePick("Issued", $vm.issued)
            datePick("Expiry", $vm.expiry)
            AppTextField(title: "Notes", text: $vm.notes, placeholder: "Optional", systemImage: "text.alignleft")
        }
    }

    private func datePick(_ title: String, _ binding: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased()).font(.appCaption(11)).foregroundColor(Theme.textMuted)
            DatePicker("", selection: binding, displayedComponents: .date).labelsHidden().accentColor(Theme.accent)
        }
    }

    private func expirySheet(_ doc: ProjectDocument) -> some View {
        ExpirySheet(doc: doc) { date in vm.setExpiry(date, for: doc); expiryTarget = nil }
            onCancel: { expiryTarget = nil }
    }
}

private struct ExpirySheet: View {
    let doc: ProjectDocument
    let onSet: (Date) -> Void
    let onCancel: () -> Void
    @State private var date: Date
    init(doc: ProjectDocument, onSet: @escaping (Date) -> Void, onCancel: @escaping () -> Void) {
        self.doc = doc; self.onSet = onSet; self.onCancel = onCancel
        _date = State(initialValue: doc.expiry)
    }
    var body: some View {
        FormSheet(title: "Set Expiry", saveTitle: "Set",
                  onSave: { onSet(date) }, onCancel: onCancel) {
            Text(doc.name).font(.appHeadline(16)).foregroundColor(Theme.textPrimary)
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle()).accentColor(Theme.accent)
        }
    }
}

// MARK: - Supplier / Quote Compare (Screen 2)

struct QuoteCompareView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var toast: ToastCenter
    @StateObject private var vm = QuoteCompareViewModel()
    @State private var showAdd = false

    private var cheapest: Quote? { store.quotes.min { $0.price < $1.price } }
    private var fastest: Quote? { store.quotes.min { $0.leadDays < $1.leadDays } }

    var body: some View {
        ScreenScaffold {
            HStack(spacing: 12) {
                PrimaryButton(title: "Add Quote", systemImage: "plus") { showAdd = true }
                SecondaryButton(title: "Choose Best", systemImage: "rosette", tint: Theme.success) { vm.chooseBest() }
            }
            if store.quotes.isEmpty {
                Card { EmptyStateView(systemImage: "doc.on.doc", title: "No quotes",
                                      message: "Add supplier quotes to compare price, lead time and delivery.") }
            } else {
                ForEach(store.quotes) { quote in quoteCard(quote) }
            }
        }
        .navigationBarTitle("Quote Compare", displayMode: .inline)
        .onAppear { vm.configure(store, settings, toast) }
        .sheet(isPresented: $showAdd) { addSheet }
    }

    private func quoteCard(_ quote: Quote) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(quote.supplier).font(.appHeadline(17)).foregroundColor(Theme.textPrimary)
                    if quote.isChosen { Chip(text: "Chosen", color: Theme.success, filled: true) }
                    Spacer()
                    Text(settings.money(quote.price)).font(.appNumber(20)).foregroundColor(Theme.accent)
                }
                HStack(spacing: 8) {
                    InfoPill(icon: "clock", text: "\(quote.leadDays)d lead",
                             tint: fastest?.id == quote.id ? Theme.success : Theme.blue)
                    if cheapest?.id == quote.id { InfoPill(icon: "tag", text: "Cheapest", tint: Theme.success) }
                    if !quote.deliveryNote.isEmpty { InfoPill(icon: "shippingbox", text: quote.deliveryNote, tint: Theme.teal) }
                }
                if !quote.notes.isEmpty {
                    Text(quote.notes).font(.appCaption(12)).foregroundColor(Theme.textMuted)
                }
                HStack {
                    Button(action: { vm.choose(quote) }) {
                        Label(quote.isChosen ? "Selected" : "Choose", systemImage: quote.isChosen ? "checkmark.circle.fill" : "circle")
                            .font(.appCaption(13)).foregroundColor(quote.isChosen ? Theme.success : Theme.accent)
                    }
                    Spacer()
                    Button(action: { vm.delete(quote) }) {
                        Image(systemName: "trash").font(.system(size: 13)).foregroundColor(Theme.danger)
                    }
                }
            }
        }
    }

    private var addSheet: some View {
        FormSheet(title: "Add Quote", saveTitle: "Add", canSave: vm.canAdd,
                  onSave: { vm.addQuote(); showAdd = false }, onCancel: { showAdd = false }) {
            AppTextField(title: "Supplier", text: $vm.supplier, placeholder: "e.g. TileWorld", systemImage: "building.2")
            HStack(spacing: 12) {
                AppNumberField(title: "Price", value: $vm.price, suffix: settings.currencySymbol, systemImage: "dollarsign")
                AppNumberField(title: "Lead days", value: $vm.leadDays, suffix: "d", systemImage: "clock")
            }
            AppTextField(title: "Delivery", text: $vm.deliveryNote, placeholder: "e.g. Free over $1500", systemImage: "shippingbox")
            AppTextField(title: "Notes", text: $vm.notes, placeholder: "Optional", systemImage: "text.alignleft")
        }
    }
}
