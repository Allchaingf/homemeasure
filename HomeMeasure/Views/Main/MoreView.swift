//
//  MoreView.swift
//  HomeMeasure
//
//  The "More" hub. Groups every remaining functional screen by section so all
//  23 screens are reachable. Each row is a real NavigationLink to a built view.
//

import SwiftUI

struct MoreView: View {
    @EnvironmentObject var store: ProjectStore

    var body: some View {
        ScreenScaffold {
            header
            group("Planning", "square.stack.3d.up.fill", [
                .init("New Work Area", "square.badge.plus", Theme.blue, AnyView(ProjectIntakeView())),
                .init("Build Stages", "flowchart", Theme.accent, AnyView(WorkStagesView())),
                .init("Project Tasks", "list.bullet", Theme.teal, AnyView(TaskBoardView())),
                .init("Work Assignments", "person.2.fill", Theme.purple, AnyView(CrewPlannerView()))
            ])
            group("Schedule", "calendar", [
                .init("Project Timeline", "calendar.badge.clock", Theme.blue, AnyView(TimelineCalendarView()))
            ])
            group("Money", "dollarsign.circle.fill", [
                .init("Estimate Builder", "doc.text.fill", Theme.accent, AnyView(EstimateBuilderView())),
                .init("Materials", "shippingbox.fill", Theme.teal, AnyView(MaterialListView())),
                .init("Budget by Room", "chart.pie.fill", Theme.blue, AnyView(BudgetSplitView()))
            ])
            group("Analytics", "chart.line.uptrend.xyaxis", [
                .init("Progress Trends", "chart.bar.fill", Theme.blue, AnyView(ProgressAnalyticsView())),
                .init("Cost Trends", "chart.line.uptrend.xyaxis", Theme.accent, AnyView(CostAnalyticsView()))
            ])
            group("Reports", "doc.richtext.fill", [
                .init("Build Report", "doc.text.fill", Theme.accent, AnyView(ReportBuilderView())),
                .init("Quote Compare", "doc.on.doc.fill", Theme.blue, AnyView(QuoteCompareView())),
                .init("Documents & Permits", "checkmark.shield.fill", Theme.teal, AnyView(PermitTrackerView()))
            ])
            group("Quality & Safety", "checkmark.seal.fill", [
                .init("Issues & Blockers", "exclamationmark.triangle.fill", Theme.danger, AnyView(IssueLogView())),
                .init("Quality Criteria", "checkmark.circle.fill", Theme.success, AnyView(QualityCheckView())),
                .init("Final Punch List", "list.bullet", Theme.accent, AnyView(PunchListView())),
                .init("Safety Check", "shield.lefthalf.fill", Theme.warning, AnyView(SafetyChecklistView())),
                .init("Tools & Equipment", "wrench.and.screwdriver.fill", Theme.blue, AnyView(ToolInventoryView())),
                .init("Site Photo Notes", "photo.fill", Theme.purple, AnyView(PhotoMarkupView()))
            ])
            group("App", "gearshape.fill", [
                .init("App Preferences", "slider.horizontal.3", Theme.textSecondary, AnyView(SettingsView()))
            ])
        }
        .navigationBarTitle("More", displayMode: .inline)
    }

    private var header: some View {
        Card {
            HStack(spacing: 14) {
                Image(systemName: "house.fill").font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white).frame(width: 52, height: 52)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Theme.actionGradient))
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.projectName).font(.appHeadline(18)).foregroundColor(Theme.textPrimary)
                    Text("All tools · offline").font(.appCaption(12)).foregroundColor(Theme.textMuted)
                }
                Spacer()
            }
        }
    }

    private func group(_ title: String, _ icon: String, _ items: [MoreItem]) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 4) {
                SectionHeader(title: title, systemImage: icon).padding(.bottom, 6)
                ForEach(items) { item in
                    NavigationLink(destination: item.destination) {
                        HStack(spacing: 12) {
                            Image(systemName: item.icon).foregroundColor(item.tint).frame(width: 26)
                            Text(item.title).font(.appBody(15)).foregroundColor(Theme.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.textMuted)
                        }
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(ScaleButtonStyle(scale: 0.98))
                    if item.id != items.last?.id { Divider().background(Theme.stroke) }
                }
            }
        }
    }
}

private struct MoreItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let tint: Color
    let destination: AnyView
    init(_ title: String, _ icon: String, _ tint: Color, _ destination: AnyView) {
        self.title = title; self.icon = icon; self.tint = tint; self.destination = destination
    }
}
