//
//  SharedViews.swift
//  HomeMeasure
//
//  Reusable layout pieces shared by the functional screens: the blueprint
//  scaffold, room pickers, bar charts, form sheets and a share sheet.
//

import SwiftUI

// MARK: - Screen scaffold

struct ScreenScaffold<Content: View>: View {
    var spacing: CGFloat = 16
    let content: Content
    init(spacing: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    var body: some View {
        ZStack {
            BlueprintBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: spacing) {
                    content
                }
                .padding(16)
                .tabBarInset()
            }
        }
    }
}

// MARK: - Room picker chips

struct RoomChips: View {
    let rooms: [Room]
    @Binding var selection: UUID?
    var includeNone: Bool = true
    var noneLabel: String = "Unassigned"

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if includeNone {
                    SelectableChip(text: noneLabel, isSelected: selection == nil, color: Theme.textMuted) {
                        selection = nil
                    }
                }
                ForEach(rooms) { room in
                    SelectableChip(text: room.name, isSelected: selection == room.id,
                                   color: Color(hex: room.colorHex)) {
                        selection = room.id
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
}

// MARK: - Enum picker chips (generic)

struct EnumChips<T: CaseIterable & Identifiable & Equatable>: View where T.AllCases == [T] {
    @Binding var selection: T
    let title: (T) -> String
    var tint: Color = Theme.accent
    var icon: ((T) -> String)? = nil

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(T.allCases) { value in
                    SelectableChip(text: title(value), systemImage: icon?(value),
                                   isSelected: selection == value, color: tint) {
                        selection = value
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
}

// MARK: - Charts

/// Horizontal bar chart: label · bar · caption. Robust for any count.
struct HBarChart: View {
    let data: [BarDatum]
    var normalized: Bool = false   // values are already 0...1

    private var maxValue: Double {
        normalized ? 1 : max(data.map { $0.value }.max() ?? 1, 0.0001)
    }

    var body: some View {
        VStack(spacing: 12) {
            ForEach(data) { d in
                HStack(spacing: 10) {
                    Text(d.label)
                        .font(.appCaption(12)).foregroundColor(Theme.textSecondary)
                        .frame(width: 88, alignment: .leading).lineLimit(1)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.surfaceAlt)
                            Capsule()
                                .fill(LinearGradient(colors: [d.tint.opacity(0.7), d.tint],
                                                     startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(6, CGFloat(d.value / maxValue) * geo.size.width))
                        }
                    }
                    .frame(height: 16)
                    Text(d.caption)
                        .font(.appCaption(12)).foregroundColor(Theme.textPrimary)
                        .frame(width: 64, alignment: .trailing).lineLimit(1)
                }
            }
        }
    }
}

/// Vertical bar chart used for weekly trends.
struct VBarChart: View {
    let data: [BarDatum]
    private var maxValue: Double { max(data.map { $0.value }.max() ?? 1, 1) }

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(data) { d in
                VStack(spacing: 6) {
                    Text(d.caption).font(.appCaption(10)).foregroundColor(Theme.textMuted)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(colors: [d.tint, d.tint.opacity(0.5)],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(height: max(6, CGFloat(d.value / maxValue) * 120))
                    Text(d.label).font(.appCaption(10)).foregroundColor(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 160)
    }
}

// MARK: - Form sheet scaffold

struct FormSheet<Content: View>: View {
    let title: String
    var saveTitle: String = "Save"
    var canSave: Bool = true
    let onSave: () -> Void
    let onCancel: () -> Void
    let content: Content

    init(title: String, saveTitle: String = "Save", canSave: Bool = true,
         onSave: @escaping () -> Void, onCancel: @escaping () -> Void,
         @ViewBuilder content: () -> Content) {
        self.title = title
        self.saveTitle = saveTitle
        self.canSave = canSave
        self.onSave = onSave
        self.onCancel = onCancel
        self.content = content()
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button("Cancel", action: onCancel)
                        .foregroundColor(Theme.textMuted)
                    Spacer()
                    Text(title).font(.appHeadline(17)).foregroundColor(Theme.textPrimary)
                    Spacer()
                    Button(saveTitle, action: onSave)
                        .font(.appHeadline(16))
                        .foregroundColor(canSave ? Theme.accent : Theme.textMuted)
                        .disabled(!canSave)
                }
                .padding(16)
                .background(Theme.surface)
                .overlay(Rectangle().fill(Theme.stroke).frame(height: 1), alignment: .bottom)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) { content }
                        .padding(16)
                }
            }
        }
    }
}

// MARK: - Share sheet (UIActivityViewController)

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Small reusable rows

struct InfoPill: View {
    let icon: String
    let text: String
    var tint: Color = Theme.blue
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 11, weight: .bold))
            Text(text).font(.appCaption(12))
        }
        .foregroundColor(tint)
        .padding(.horizontal, 9).padding(.vertical, 5)
        .background(Capsule().fill(tint.opacity(0.12)))
    }
}

/// Star rating row (tap to set).
struct StarRating: View {
    let rating: Int
    let onSet: (Int) -> Void
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .foregroundColor(i <= rating ? Theme.warning : Theme.textMuted)
                    .onTapGesture { onSet(i) }
            }
        }
    }
}

// Shared date formatter helper.
enum DateFmt {
    static let medium: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; return f
    }()
    static func string(_ date: Date) -> String { medium.string(from: date) }
    static func relativeDays(to date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days == 0 { return "Today" }
        if days > 0 { return "in \(days)d" }
        return "\(-days)d ago"
    }
}
