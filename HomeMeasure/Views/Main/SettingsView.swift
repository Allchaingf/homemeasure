//
//  SettingsView.swift
//  HomeMeasure
//
//  Screen 23 — App Preferences. Every control is fully wired: theme switching
//  applies instantly and persists, units/currency reformat the whole app,
//  the notifications toggle schedules/cancels real local notifications, and the
//  data buttons reset or clear the actual store. No account / profile anywhere.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var toast: ToastCenter
    @ObservedObject private var notifications = NotificationManager.shared
    @State private var projectName = ""
    @State private var showResetConfirm = false
    @State private var showClearConfirm = false

    var body: some View {
        ScreenScaffold {
            project
            appearance
            measurement
            notificationsCard
            data
            about
        }
        .navigationBarTitle("App Preferences", displayMode: .inline)
        .onAppear { projectName = store.projectName; notifications.refreshStatus() }
        .alert(isPresented: $showResetConfirm) {
            Alert(title: Text("Reset sample data?"),
                  message: Text("This replaces all current records with the demo project."),
                  primaryButton: .destructive(Text("Reset")) {
                      store.resetSampleData(); toast.show("Sample data restored")
                  },
                  secondaryButton: .cancel())
        }
    }

    // MARK: Project
    private var project: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Project", systemImage: "folder.fill")
                AppTextField(title: "Project name", text: $projectName, placeholder: "My Renovation", systemImage: "pencil")
                PrimaryButton(title: "Save Name", systemImage: "checkmark") {
                    let name = projectName.trimmingCharacters(in: .whitespaces)
                    guard !name.isEmpty else { toast.show("Enter a name", icon: "exclamationmark.triangle.fill", color: Theme.warning); return }
                    store.projectName = name
                    toast.show("Project name saved")
                }
            }
        }
    }

    // MARK: Appearance
    private var appearance: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Appearance", subtitle: "Theme applies instantly", systemImage: "paintpalette.fill")
                HStack(spacing: 10) {
                    ForEach(ThemeMode.allCases) { mode in
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { settings.themeMode = mode }
                            toast.show("\(mode.title) theme")
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: mode.icon).font(.system(size: 20, weight: .bold))
                                Text(mode.title).font(.appCaption(12))
                            }
                            .foregroundColor(settings.themeMode == mode ? .white : Theme.textSecondary)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 12)
                                .fill(settings.themeMode == mode ? Theme.accent : Theme.surfaceAlt))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            }
        }
    }

    // MARK: Measurement / money
    private var measurement: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Units & Currency", systemImage: "ruler.fill")
                VStack(alignment: .leading, spacing: 8) {
                    Text("UNITS").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                    HStack(spacing: 10) {
                        ForEach(UnitSystem.allCases) { u in
                            SelectableChip(text: u.title, isSelected: settings.unitSystem == u, color: Theme.blue) {
                                settings.unitSystem = u; toast.show("Units: \(u.lengthUnit)")
                            }
                        }
                    }
                }
                SecondaryButton(title: "Change Units", systemImage: "arrow.left.arrow.right", tint: Theme.blue) {
                    settings.unitSystem = settings.unitSystem == .metric ? .imperial : .metric
                    toast.show("Switched to \(settings.unitSystem == .metric ? "Metric" : "Imperial")")
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("CURRENCY").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                    Menu {
                        ForEach(AppSettings.currencies, id: \.code) { c in
                            Button(action: { settings.currencyCode = c.code; toast.show("Currency: \(c.code)") }) {
                                Text("\(c.symbol)  \(c.name) (\(c.code))")
                            }
                        }
                    } label: {
                        HStack {
                            Text("\(settings.currencySymbol)  \(settings.currencyCode)")
                                .font(.appBody(16)).foregroundColor(Theme.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down").foregroundColor(Theme.textMuted)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: Metrics.radiusSmall).fill(Theme.surfaceAlt))
                        .overlay(RoundedRectangle(cornerRadius: Metrics.radiusSmall).stroke(Theme.stroke, lineWidth: 1))
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("DEFAULT DETAIL LEVEL").font(.appCaption(11)).foregroundColor(Theme.textMuted)
                    HStack(spacing: 10) {
                        ForEach(DetailLevel.allCases) { lvl in
                            SelectableChip(text: lvl.title, isSelected: settings.detailLevel == lvl, color: Theme.accent) {
                                settings.detailLevel = lvl; toast.show("Detail: \(lvl.title)")
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: Notifications
    private var notificationsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Notifications & Haptics", systemImage: "bell.fill")
                Toggle(isOn: Binding(get: { settings.notificationsEnabled },
                                     set: { handleNotifications($0) })) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Local reminders").font(.appBody(15)).foregroundColor(Theme.textPrimary)
                        Text(notifications.authorized ? "Permission granted" : "Schedules on-device only")
                            .font(.appCaption(11)).foregroundColor(Theme.textMuted)
                    }
                }.toggleStyle(SwitchToggleStyle(tint: Theme.accent))

                if settings.notificationsEnabled {
                    SecondaryButton(title: "Send Test Reminder", systemImage: "bell.badge", tint: Theme.blue) {
                        NotificationManager.shared.scheduleSampleReminder()
                        toast.show("Reminder scheduled in 10s", icon: "bell.fill")
                    }
                }

                Toggle(isOn: $settings.hapticsEnabled) {
                    Text("Haptic feedback").font(.appBody(15)).foregroundColor(Theme.textPrimary)
                }.toggleStyle(SwitchToggleStyle(tint: Theme.accent))
            }
        }
    }

    private func handleNotifications(_ on: Bool) {
        if on {
            NotificationManager.shared.requestAuthorization { granted in
                if granted {
                    settings.notificationsEnabled = true
                    NotificationManager.shared.scheduleSampleReminder()
                    toast.show("Notifications enabled")
                } else {
                    settings.notificationsEnabled = false
                    toast.show("Permission denied — enable in Settings",
                               icon: "exclamationmark.triangle.fill", color: Theme.warning)
                }
            }
        } else {
            settings.notificationsEnabled = false
            NotificationManager.shared.cancelAll()
            toast.show("Notifications off")
        }
    }

    // MARK: Data
    private var data: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Data", subtitle: "Stored locally on this device", systemImage: "externaldrive.fill")
                PrimaryButton(title: "Reset Sample Data", systemImage: "arrow.counterclockwise") { showResetConfirm = true }
                Button(action: { showClearConfirm = true }) {
                    HStack { Image(systemName: "trash"); Text("Clear All Data").font(.appHeadline(16)) }
                        .foregroundColor(Theme.danger)
                        .padding(.vertical, 14).frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: Metrics.radiusSmall).fill(Theme.danger.opacity(0.12)))
                        .overlay(RoundedRectangle(cornerRadius: Metrics.radiusSmall).stroke(Theme.danger.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(ScaleButtonStyle())
                .alert(isPresented: $showClearConfirm) {
                    Alert(title: Text("Clear all data?"),
                          message: Text("Deletes every record. This cannot be undone."),
                          primaryButton: .destructive(Text("Clear")) {
                              store.clearAll(); toast.show("All data cleared", icon: "trash", color: Theme.danger)
                          },
                          secondaryButton: .cancel())
                }
            }
        }
    }

    // MARK: About
    private var about: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "About", systemImage: "info.circle.fill")
                infoRow("Version", "1.0")
                infoRow("Mode", "Offline · no account")
                infoRow("Records", "\(store.rooms.count) rooms · \(store.tasks.count) tasks")
                Text("HomeMeasure keeps everything on your device. No sign-in, no profile, no cloud.")
                    .font(.appCaption(12)).foregroundColor(Theme.textMuted)
            }
        }
    }

    private func infoRow(_ a: String, _ b: String) -> some View {
        HStack {
            Text(a).font(.appBody(14)).foregroundColor(Theme.textSecondary)
            Spacer()
            Text(b).font(.appBody(14)).foregroundColor(Theme.textPrimary)
        }
    }
}
