//
//  RoomsViews.swift
//  HomeMeasure
//
//  Screen 13 — Rooms & Zones (Room Builder), Screen 12 — New Work Area
//  (Project Intake) and a detailed room view that ties measurements,
//  materials, tasks and cost together.
//

import SwiftUI

// MARK: - Room Builder (Screen 13)

struct RoomBuilderView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var toast: ToastCenter
    @StateObject private var vm = RoomBuilderViewModel()
    @State private var showForm = false

    var body: some View {
        ScreenScaffold {
            HStack {
                PrimaryButton(title: "Create Room", systemImage: "plus") {
                    vm.reset(); showForm = true
                }
                NavigationLink(destination: ProjectIntakeView()) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.badge.plus")
                        Text("New Area").font(.appHeadline(15))
                    }
                    .foregroundColor(Theme.teal)
                    .padding(.vertical, 14).padding(.horizontal, 16)
                    .background(RoundedRectangle(cornerRadius: Metrics.radiusSmall).fill(Theme.teal.opacity(0.12)))
                }
                .buttonStyle(ScaleButtonStyle())
            }

            if store.rooms.isEmpty {
                Card { EmptyStateView(systemImage: "square.split.bottomrightquarter",
                                      title: "No rooms yet",
                                      message: "Create a room or add a work area to start structuring your project.") }
            } else {
                ForEach(store.rooms) { room in
                    RoomCard(room: room,
                             planned: store.plannedCost(forRoom: room.id),
                             progress: store.progress(forRoom: room.id),
                             measureCount: store.measurements.filter { $0.roomID == room.id }.count,
                             materialCount: store.materials.filter { $0.roomID == room.id }.count,
                             onEdit: { vm.load(room); showForm = true },
                             onStatus: { vm.setStatus($0, for: room) },
                             onDelete: { vm.delete(room) })
                }
            }
        }
        .navigationBarTitle("Rooms & Zones", displayMode: .inline)
        .onAppear { vm.configure(store, settings, toast) }
        .sheet(isPresented: $showForm) { roomForm }
    }

    private var roomForm: some View {
        FormSheet(title: vm.isEditing ? "Edit Details" : "Create Room",
                  saveTitle: vm.isEditing ? "Update" : "Create", canSave: vm.canSave,
                  onSave: { vm.save(); showForm = false },
                  onCancel: { showForm = false }) {
            AppTextField(title: "Room name", text: $vm.name, placeholder: "e.g. Kitchen",
                         systemImage: "square.split.bottomrightquarter.fill")
            field("Type") { EnumChips(selection: $vm.type, title: { $0.title }, tint: Theme.blue, icon: { $0.icon }) }
            AppNumberField(title: "Planned area", value: $vm.area, suffix: settings.unitSystem.areaUnit, systemImage: "ruler")
            field("Priority") { EnumChips(selection: $vm.priority, title: { $0.title }, tint: Theme.accent) }
            field("Color") {
                HStack(spacing: 10) {
                    ForEach(vm.palette, id: \.self) { hex in
                        Circle().fill(Color(hex: hex)).frame(width: 30, height: 30)
                            .overlay(Circle().stroke(Color.white, lineWidth: vm.colorHex == hex ? 3 : 0))
                            .overlay(Circle().stroke(Theme.stroke, lineWidth: 1))
                            .onTapGesture { vm.colorHex = hex }
                    }
                }
            }
            AppTextField(title: "Scope", text: $vm.scope, placeholder: "What's the work?", systemImage: "text.alignleft")
            field("Target date") {
                DatePicker("", selection: $vm.targetDate, displayedComponents: .date)
                    .labelsHidden().accentColor(Theme.accent)
            }
        }
    }

    private func field<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased()).font(.appCaption(11)).foregroundColor(Theme.textMuted)
            content()
        }
    }
}

private struct RoomCard: View {
    let room: Room
    let planned: Double
    let progress: Double
    let measureCount: Int
    let materialCount: Int
    let onEdit: () -> Void
    let onStatus: (BuildStatus) -> Void
    let onDelete: () -> Void
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: room.type.icon)
                        .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: room.colorHex)))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(room.name).font(.appHeadline(17)).foregroundColor(Theme.textPrimary)
                        HStack(spacing: 6) {
                            Chip(text: room.type.title, color: Theme.blue)
                            Chip(text: room.priority.title, color: room.priority.tint)
                        }
                    }
                    Spacer()
                    Menu {
                        ForEach(BuildStatus.allCases) { s in
                            Button(action: { onStatus(s) }) { Label(s.title, systemImage: "circle.fill") }
                        }
                    } label: {
                        Chip(text: room.status.title, color: room.status.tint, filled: true)
                    }
                }

                ProgressBar(value: progress, tint: Color(hex: room.colorHex))

                HStack(spacing: 16) {
                    InfoPill(icon: "ruler", text: settings.area(room.plannedArea), tint: Theme.teal)
                    InfoPill(icon: "square.dashed", text: "\(measureCount) measures", tint: Theme.blue)
                    InfoPill(icon: "shippingbox", text: "\(materialCount) mats", tint: Theme.accent)
                }

                HStack {
                    Text("Planned \(settings.money(planned))")
                        .font(.appCaption(12)).foregroundColor(Theme.textSecondary)
                    Spacer()
                    NavigationLink(destination: RoomDetailView(roomID: room.id)) {
                        Text("Open").font(.appCaption(13)).foregroundColor(Theme.blue)
                    }
                    Button(action: onEdit) {
                        Text("Edit Details").font(.appCaption(13)).foregroundColor(Theme.accent)
                    }
                    Button(action: onDelete) {
                        Image(systemName: "trash").font(.system(size: 13)).foregroundColor(Theme.danger)
                    }
                }
            }
        }
    }
}

// MARK: - Project Intake (Screen 12)

struct ProjectIntakeView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var toast: ToastCenter
    @StateObject private var vm = IntakeViewModel()
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ScreenScaffold {
            Card {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "Define a work area",
                                  subtitle: "Used in estimates, tasks and reports",
                                  systemImage: "square.badge.plus")
                    AppTextField(title: "Area name", text: $vm.name, placeholder: "e.g. Garage",
                                 systemImage: "square.split.bottomrightquarter.fill")
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TYPE").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                        EnumChips(selection: $vm.type, title: { $0.title }, tint: Theme.blue, icon: { $0.icon })
                    }
                    AppNumberField(title: "Approx area", value: $vm.area,
                                   suffix: settings.unitSystem.areaUnit, systemImage: "ruler")
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PRIORITY").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                        EnumChips(selection: $vm.priority, title: { $0.title }, tint: Theme.accent)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SCOPE").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                        TextEditor(text: $vm.scope)
                            .frame(height: 90).padding(8)
                            .background(RoundedRectangle(cornerRadius: Metrics.radiusSmall).fill(Theme.surfaceAlt))
                            .overlay(RoundedRectangle(cornerRadius: Metrics.radiusSmall).stroke(Theme.stroke, lineWidth: 1))
                            .font(.appBody(15))
                    }
                }
            }

            HStack(spacing: 12) {
                PrimaryButton(title: "Add Area", systemImage: "plus") {
                    if vm.addArea() { presentationMode.wrappedValue.dismiss() }
                }
                SecondaryButton(title: "Save Scope", systemImage: "tray.and.arrow.down", tint: Theme.teal) {
                    vm.saveScope()
                }
            }
        }
        .navigationBarTitle("New Work Area", displayMode: .inline)
        .onAppear { vm.configure(store, settings, toast) }
    }
}

// MARK: - Room Detail

struct RoomDetailView: View {
    let roomID: UUID
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var settings: AppSettings

    private var room: Room? { store.room(roomID) }

    var body: some View {
        ScreenScaffold {
            if let room = room {
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: room.type.icon).font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white).frame(width: 48, height: 48)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: room.colorHex)))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(room.name).font(.appTitle(20)).foregroundColor(Theme.textPrimary)
                                Text(room.scope.isEmpty ? "No scope set" : room.scope)
                                    .font(.appCaption(12)).foregroundColor(Theme.textMuted)
                            }
                            Spacer()
                        }
                        ProgressBar(value: store.progress(forRoom: room.id), tint: Color(hex: room.colorHex))
                        HStack(spacing: 10) {
                            InfoPill(icon: "ruler", text: settings.area(room.plannedArea), tint: Theme.teal)
                            InfoPill(icon: "flag", text: room.priority.title, tint: room.priority.tint)
                            InfoPill(icon: "calendar", text: DateFmt.string(room.targetDate), tint: Theme.blue)
                        }
                    }
                }

                detailList("Measurements", icon: "square.dashed",
                           items: store.measurements.filter { $0.roomID == room.id }.map {
                               "\($0.label): \(settings.formatNumber($0.resultWithWaste)) \($0.kind == .linear ? settings.unitSystem.lengthUnit : settings.unitSystem.areaUnit)"
                           })
                detailList("Materials", icon: "shippingbox",
                           items: store.materials.filter { $0.roomID == room.id }.map {
                               "\($0.name) — \(settings.formatNumber($0.quantity)) \($0.unit) · \($0.status.title)"
                           })
                detailList("Tasks", icon: "list.bullet",
                           items: store.tasks.filter { $0.roomID == room.id }.map {
                               "[\($0.state.title)] \($0.title)"
                           })

                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Cost", systemImage: "dollarsign.circle.fill")
                        costRow("Planned", store.plannedCost(forRoom: room.id))
                        costRow("Committed", store.committedCost(forRoom: room.id))
                        if store.limit(forRoom: room.id) > 0 {
                            costRow("Budget limit", store.limit(forRoom: room.id))
                        }
                    }
                }
            } else {
                Card { EmptyStateView(systemImage: "questionmark", title: "Room not found", message: "It may have been deleted.") }
            }
        }
        .navigationBarTitle(room?.name ?? "Room", displayMode: .inline)
    }

    private func detailList(_ title: String, icon: String, items: [String]) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: title, systemImage: icon)
                if items.isEmpty {
                    Text("None yet.").font(.appBody(14)).foregroundColor(Theme.textMuted)
                } else {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, line in
                        HStack(alignment: .top, spacing: 8) {
                            Circle().fill(Theme.accent).frame(width: 6, height: 6).padding(.top, 6)
                            Text(line).font(.appBody(14)).foregroundColor(Theme.textPrimary)
                        }
                    }
                }
            }
        }
    }

    private func costRow(_ label: String, _ value: Double) -> some View {
        HStack {
            Text(label).font(.appBody(14)).foregroundColor(Theme.textSecondary)
            Spacer()
            Text(settings.money(value)).font(.appHeadline(15)).foregroundColor(Theme.textPrimary)
        }
    }
}
