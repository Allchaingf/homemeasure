//
//  MeasurementPadView.swift
//  HomeMeasure
//
//  Screen 14 — Measurements. Enter length/width/height, choose a kind, add a
//  waste allowance and calculate area/length/volume per room. Buttons:
//  Add Measure / Calculate.
//

import SwiftUI

struct MeasurementPadView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var toast: ToastCenter
    @StateObject private var vm = MeasurementViewModel()

    var body: some View {
        ScreenScaffold {
            calculator
            results
            saved
        }
        .navigationBarTitle("Measurements", displayMode: .inline)
        .onAppear { vm.configure(store, settings, toast) }
    }

    private var calculator: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "New measurement", systemImage: "ruler.fill")
                EnumChips(selection: $vm.kind, title: { $0.title }, tint: Theme.teal, icon: { $0.icon })
                AppTextField(title: "Label", text: $vm.label, placeholder: "e.g. Floor area", systemImage: "tag")
                VStack(alignment: .leading, spacing: 6) {
                    Text("ROOM").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                    RoomChips(rooms: store.rooms, selection: $vm.roomID)
                }
                HStack(spacing: 12) {
                    AppNumberField(title: "Length", value: $vm.length, suffix: settings.unitSystem.lengthUnit, systemImage: "arrow.left.and.right")
                    if vm.kind != .linear {
                        AppNumberField(title: "Width", value: $vm.width, suffix: settings.unitSystem.lengthUnit, systemImage: "arrow.up.and.down")
                    }
                }
                if vm.kind == .volume {
                    AppNumberField(title: "Height", value: $vm.height, suffix: settings.unitSystem.lengthUnit, systemImage: "arrow.up.and.down")
                }
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("WASTE ALLOWANCE").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                        Spacer()
                        Text("\(Int(vm.waste))%").font(.appCaption(12)).foregroundColor(Theme.accent)
                    }
                    Slider(value: $vm.waste, in: 0...30, step: 1).accentColor(Theme.accent)
                }
                HStack(spacing: 12) {
                    PrimaryButton(title: "Add Measure", systemImage: "plus") { vm.add() }
                    SecondaryButton(title: "Calculate", systemImage: "function", tint: Theme.blue) { vm.calculate() }
                }
            }
        }
    }

    private var results: some View {
        Card {
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("RESULT").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                        Text(unit(vm.preview))
                            .font(.appNumber(30)).foregroundColor(Theme.accent)
                    }
                    Spacer()
                    Image(systemName: vm.kind.icon).font(.system(size: 30)).foregroundColor(Theme.teal.opacity(0.6))
                }
                Divider().background(Theme.stroke)
                HStack {
                    Text("Base \(settings.formatNumber(vm.preview.baseResult))")
                        .font(.appCaption(12)).foregroundColor(Theme.textMuted)
                    Spacer()
                    Text("With \(Int(vm.waste))% waste")
                        .font(.appCaption(12)).foregroundColor(Theme.textSecondary)
                }
            }
        }
    }

    private func unit(_ m: Measurement) -> String {
        let u = m.kind == .linear ? settings.unitSystem.lengthUnit
            : (m.kind == .volume ? settings.unitSystem.lengthUnit + "³" : settings.unitSystem.areaUnit)
        return "\(settings.formatNumber(m.resultWithWaste)) \(u)"
    }

    private var saved: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Saved measurements", subtitle: "\(store.measurements.count) total", systemImage: "list.bullet.rectangle")
                if store.measurements.isEmpty {
                    Text("No measurements yet.").font(.appBody(14)).foregroundColor(Theme.textMuted)
                } else {
                    ForEach(store.measurements) { m in
                        HStack(spacing: 10) {
                            Image(systemName: m.kind.icon).foregroundColor(Theme.teal).frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(m.label).font(.appBody(15)).foregroundColor(Theme.textPrimary)
                                Text(store.roomName(m.roomID)).font(.appCaption(11)).foregroundColor(Theme.textMuted)
                            }
                            Spacer()
                            Text(unit(m)).font(.appHeadline(15)).foregroundColor(Theme.textPrimary)
                            Button(action: { vm.delete(m) }) {
                                Image(systemName: "trash").font(.system(size: 13)).foregroundColor(Theme.danger)
                            }
                        }
                        if m.id != store.measurements.last?.id { Divider().background(Theme.stroke) }
                    }
                }
            }
        }
    }
}
