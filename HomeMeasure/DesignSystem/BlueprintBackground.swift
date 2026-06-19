//
//  BlueprintBackground.swift
//  HomeMeasure
//
//  The signature backdrop of the app: a faint blueprint grid with scattered
//  "crane / construction" tick marks. Drawn with Shape paths (iOS 14 safe,
//  no Canvas) so it is cheap and renders everywhere.
//

import SwiftUI

/// A grid of light/heavy ruled lines, like engineering blueprint paper.
struct BlueprintGrid: Shape {
    var minorSpacing: CGFloat = 26

    func path(in rect: CGRect) -> Path {
        var p = Path()
        var x: CGFloat = 0
        while x <= rect.width {
            p.move(to: CGPoint(x: x, y: 0))
            p.addLine(to: CGPoint(x: x, y: rect.height))
            x += minorSpacing
        }
        var y: CGFloat = 0
        while y <= rect.height {
            p.move(to: CGPoint(x: 0, y: y))
            p.addLine(to: CGPoint(x: rect.width, y: y))
            y += minorSpacing
        }
        return p
    }
}

/// Small "+" registration marks scattered like crane / survey marks.
struct CraneMarks: View {
    // Deterministic pseudo-random positions (no Date/random needed).
    private let spots: [CGPoint] = [
        CGPoint(x: 0.12, y: 0.10), CGPoint(x: 0.78, y: 0.16),
        CGPoint(x: 0.44, y: 0.30), CGPoint(x: 0.90, y: 0.42),
        CGPoint(x: 0.18, y: 0.55), CGPoint(x: 0.62, y: 0.60),
        CGPoint(x: 0.30, y: 0.78), CGPoint(x: 0.84, y: 0.82),
        CGPoint(x: 0.08, y: 0.90), CGPoint(x: 0.52, y: 0.92)
    ]
    private let glyphs = ["plus", "ruler", "hammer", "scope", "square.dashed"]

    var body: some View {
        GeometryReader { geo in
            ForEach(Array(spots.enumerated()), id: \.offset) { idx, pt in
                Image(systemName: glyphs[idx % glyphs.count])
                    .font(.system(size: idx % 3 == 0 ? 16 : 11, weight: .light))
                    .foregroundColor(Theme.blueprintLineStrong.opacity(0.30))
                    .position(x: pt.x * geo.size.width, y: pt.y * geo.size.height)
            }
        }
    }
}

/// Full blueprint backdrop: gradient base + grid + crane marks.
struct BlueprintBackground: View {
    var showMarks: Bool = true

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            BlueprintGrid(minorSpacing: 13)
                .stroke(Theme.blueprintLine.opacity(0.18), lineWidth: 0.5)
                .ignoresSafeArea()
            BlueprintGrid(minorSpacing: 78)
                .stroke(Theme.blueprintLine.opacity(0.35), lineWidth: 0.8)
                .ignoresSafeArea()
            if showMarks {
                CraneMarks().opacity(0.9).ignoresSafeArea()
            }
        }
    }
}

struct BlueprintBackground_Previews: PreviewProvider {
    static var previews: some View {
        BlueprintBackground()
    }
}
