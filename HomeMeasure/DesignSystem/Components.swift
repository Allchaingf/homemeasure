//
//  Components.swift
//  HomeMeasure
//
//  Reusable, custom-styled UI building blocks used across every screen.
//  Nothing here uses the default SwiftUI plain styling.
//

import SwiftUI

// MARK: - Tap scale animation

struct ScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.95
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Buttons

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var fullWidth: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                if let s = systemImage { Image(systemName: s) }
                Text(title).font(.appHeadline(16))
            }
            .foregroundColor(.white)
            .padding(.vertical, 14)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, fullWidth ? 0 : 22)
            .background(Theme.actionGradient)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.radiusSmall, style: .continuous))
            .shadow(color: Theme.accent.opacity(0.35), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    var fullWidth: Bool = true
    var tint: Color = Theme.blue
    let action: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                if let s = systemImage { Image(systemName: s) }
                Text(title).font(.appHeadline(16))
            }
            .foregroundColor(tint)
            .padding(.vertical, 14)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, fullWidth ? 0 : 22)
            .background(
                RoundedRectangle(cornerRadius: Metrics.radiusSmall, style: .continuous)
                    .fill(tint.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.radiusSmall, style: .continuous)
                    .stroke(tint.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

/// Small circular icon button (used in toolbars / cards).
struct CircleIconButton: View {
    let systemImage: String
    var tint: Color = Theme.blue
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 38, height: 38)
                .background(Circle().fill(tint.opacity(0.14)))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Card

struct Card<Content: View>: View {
    var padding: CGFloat = Metrics.pad
    let content: Content
    init(padding: CGFloat = Metrics.pad, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Inputs

struct AppTextField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var systemImage: String? = nil
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.appCaption(11))
                .foregroundColor(Theme.textMuted)
            HStack(spacing: 10) {
                if let s = systemImage {
                    Image(systemName: s).foregroundColor(Theme.textMuted)
                }
                TextField(placeholder, text: $text)
                    .font(.appBody(16))
                    .foregroundColor(Theme.textPrimary)
                    .keyboardType(keyboard)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: Metrics.radiusSmall, style: .continuous)
                    .fill(Theme.surfaceAlt)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.radiusSmall, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
        }
    }
}

/// Numeric field bound to a Double via a String proxy.
struct AppNumberField: View {
    let title: String
    @Binding var value: Double
    var suffix: String = ""
    var systemImage: String? = "number"

    @State private var proxy: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.appCaption(11))
                .foregroundColor(Theme.textMuted)
            HStack(spacing: 10) {
                if let s = systemImage {
                    Image(systemName: s).foregroundColor(Theme.textMuted)
                }
                TextField("0", text: $proxy)
                    .font(.appBody(16))
                    .foregroundColor(Theme.textPrimary)
                    .keyboardType(.decimalPad)
                    .onChange(of: proxy) { newValue in
                        value = Double(newValue.replacingOccurrences(of: ",", with: ".")) ?? 0
                    }
                if !suffix.isEmpty {
                    Text(suffix).font(.appCaption(13)).foregroundColor(Theme.textMuted)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: Metrics.radiusSmall, style: .continuous)
                    .fill(Theme.surfaceAlt)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.radiusSmall, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
        }
        .onAppear { proxy = value == 0 ? "" : trimmed(value) }
    }

    private func trimmed(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(v)
    }
}

// MARK: - Chips / tags / badges

struct Chip: View {
    let text: String
    var color: Color = Theme.blue
    var filled: Bool = false
    var body: some View {
        Text(text)
            .font(.appCaption(12))
            .foregroundColor(filled ? .white : color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(filled ? color : color.opacity(0.14))
            )
    }
}

/// A selectable chip used in pickers.
struct SelectableChip: View {
    let text: String
    var systemImage: String? = nil
    let isSelected: Bool
    var color: Color = Theme.accent
    let action: () -> Void
    var body: some View {
        Button(action: {
            UISelectionFeedbackGenerator().selectionChanged()
            action()
        }) {
            HStack(spacing: 6) {
                if let s = systemImage { Image(systemName: s).font(.system(size: 12, weight: .semibold)) }
                Text(text).font(.appCaption(13))
            }
            .foregroundColor(isSelected ? .white : Theme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule().fill(isSelected ? color : Theme.surfaceAlt)
            )
            .overlay(
                Capsule().stroke(isSelected ? Color.clear : Theme.stroke, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.92))
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil
    var body: some View {
        HStack(spacing: 10) {
            if let s = systemImage {
                Image(systemName: s)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.accent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.appHeadline(17)).foregroundColor(Theme.textPrimary)
                if let sub = subtitle {
                    Text(sub).font(.appCaption(12)).foregroundColor(Theme.textMuted)
                }
            }
            Spacer()
        }
    }
}

// MARK: - Stat tile

struct StatTile: View {
    let title: String
    let value: String
    var systemImage: String = "chart.bar.fill"
    var tint: Color = Theme.blue
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(tint)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(tint.opacity(0.15)))
                Spacer()
            }
            Text(value).font(.appNumber(22)).foregroundColor(Theme.textPrimary)
            Text(title).font(.appCaption(12)).foregroundColor(Theme.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous).stroke(Theme.stroke, lineWidth: 1)
        )
    }
}

// MARK: - Progress

struct ProgressBar: View {
    var value: Double            // 0...1
    var tint: Color = Theme.accent
    var height: CGFloat = 10
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surfaceAlt)
                Capsule()
                    .fill(LinearGradient(colors: [tint.opacity(0.7), tint],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(0, min(1, value)) * geo.size.width)
            }
        }
        .frame(height: height)
    }
}

struct RingProgress: View {
    var value: Double            // 0...1
    var tint: Color = Theme.accent
    var lineWidth: CGFloat = 10
    var size: CGFloat = 84
    var body: some View {
        ZStack {
            Circle().stroke(Theme.surfaceAlt, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(max(0.001, min(1, value))))
                .stroke(LinearGradient(colors: [tint.opacity(0.6), tint],
                                       startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int((value * 100).rounded()))%")
                .font(.appHeadline(16)).foregroundColor(Theme.textPrimary)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 40, weight: .light))
                .foregroundColor(Theme.blueprintLineStrong)
            Text(title).font(.appHeadline(17)).foregroundColor(Theme.textPrimary)
            Text(message)
                .font(.appBody(14)).foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal, 24)
    }
}

// MARK: - Toast / confirmation system

final class ToastCenter: ObservableObject {
    @Published var message: String? = nil
    @Published var icon: String = "checkmark.circle.fill"
    @Published var color: Color = Theme.success
    private var token = 0

    func show(_ message: String, icon: String = "checkmark.circle.fill", color: Color = Theme.success) {
        self.message = message
        self.icon = icon
        self.color = color
        token += 1
        let current = token
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) { [weak self] in
            guard let self = self, self.token == current else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { self.message = nil }
        }
    }
}

struct ToastHost: ViewModifier {
    @ObservedObject var center: ToastCenter
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            if let msg = center.message {
                HStack(spacing: 10) {
                    Image(systemName: center.icon).foregroundColor(center.color)
                    Text(msg).font(.appHeadline(14)).foregroundColor(Theme.textPrimary)
                }
                .padding(.horizontal, 18).padding(.vertical, 12)
                .background(
                    Capsule().fill(Theme.surface)
                        .shadow(color: .black.opacity(0.18), radius: 14, y: 6)
                )
                .overlay(Capsule().stroke(center.color.opacity(0.4), lineWidth: 1))
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(99)
            }
        }
    }
}

extension View {
    func toastHost(_ center: ToastCenter) -> some View { modifier(ToastHost(center: center)) }
}
