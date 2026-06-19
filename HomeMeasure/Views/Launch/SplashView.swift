//
//  SplashView.swift
//  HomeMeasure
//
//  A thematic launch animation: a blueprint room outline draws itself while a
//  measuring sweep line travels across it, crane marks pulse, and the logo
//  springs in. Three simultaneously animated layers (background pan, midground
//  blueprint loop, foreground logo). All loops are stopped on disappear and a
//  single coordinator timer stages the sequence (no deep asyncAfter chains).
//

import SwiftUI

struct SplashView: View {
    let onFinish: () -> Void

    // Looping layer state
    @State private var panBG = false
    @State private var drawOutline = false
    @State private var sweep = false
    @State private var pulseMarks = false
    // Staged entrance/exit state
    @State private var logoShown = false
    @State private var exiting = false
    // Lifecycle
    @State private var isVisible = true
    @State private var elapsed: Double = 0
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            background
            blueprintRoom
            logo
        }
        .opacity(exiting ? 0 : 1)
        .onAppear(perform: start)
        .onDisappear(perform: stop)
    }

    // MARK: Layer 1 — background pan + glow
    private var background: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "0C2742"), Color(hex: "071726")],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            BlueprintGrid(minorSpacing: 30)
                .stroke(Color(hex: "2C699B").opacity(0.30), lineWidth: 0.6)
                .ignoresSafeArea()
                .offset(x: panBG ? 20 : -20, y: panBG ? -20 : 20)
            RadialGradient(colors: [Theme.accent.opacity(0.35), .clear],
                           center: .center, startRadius: 5,
                           endRadius: panBG ? 320 : 200)
                .ignoresSafeArea()
                .blendMode(.screen)
        }
    }

    // MARK: Layer 2 — blueprint room being measured (loops)
    private var blueprintRoom: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .trim(from: 0, to: drawOutline ? 1 : 0.02)
                .stroke(Theme.teal.opacity(0.9),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 0]))
                .frame(width: 220, height: 150)

            // dimension annotation
            HStack(spacing: 4) {
                Image(systemName: "ruler")
                Text("4.2 m")
            }
            .font(.appCaption(12))
            .foregroundColor(Theme.teal.opacity(0.85))
            .offset(y: -92)

            // moving measuring sweep line
            Rectangle()
                .fill(Theme.accent.opacity(0.85))
                .frame(width: 2, height: 150)
                .shadow(color: Theme.accent, radius: 6)
                .offset(x: sweep ? 100 : -100)

            // pulsing crane / registration marks at the corners
            ForEach(0..<4, id: \.self) { i in
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.accent.opacity(0.9))
                    .scaleEffect(pulseMarks ? 1.25 : 0.75)
                    .offset(x: i % 2 == 0 ? -110 : 110,
                            y: i < 2 ? -75 : 75)
            }
        }
        .opacity(exiting ? 0 : 0.95)
        .offset(y: -40)
    }

    // MARK: Layer 3 — logo + title (spring entrance, scale-up exit)
    private var logo: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Theme.actionGradient)
                    .frame(width: 96, height: 96)
                    .shadow(color: Theme.accent.opacity(0.5), radius: 18, y: 8)
                Image(systemName: "house.fill")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.white)
                    .offset(y: -4)
                Image(systemName: "ruler.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                    .offset(y: 22)
            }
            VStack(spacing: 4) {
                Text("HomeMeasure")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("MEASURE · PLAN · BUILD")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .tracking(3)
                    .foregroundColor(Theme.teal)
            }
        }
        .scaleEffect(exiting ? 1.6 : (logoShown ? 1 : 0.6))
        .opacity(logoShown ? 1 : 0)
        .offset(y: 120)
    }

    // MARK: Coordinator

    private func start() {
        isVisible = true
        elapsed = 0
        // Three infinite loops kicked off together.
        withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) { panBG = true }
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { drawOutline = true }
        withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) { sweep = true }
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { pulseMarks = true }

        // Single coordinator timer drives the staged sequence.
        let t = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            guard isVisible else { return }
            elapsed += 0.05
            if elapsed >= 1.4 && !logoShown {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) { logoShown = true }
            }
            if elapsed >= 2.5 && !exiting {
                withAnimation(.easeIn(duration: 0.45)) { exiting = true }
            }
            if elapsed >= 2.95 {
                stop()
                onFinish()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stop() {
        isVisible = false
        timer?.invalidate()
        timer = nil
        // Reset looping state so nothing leaks into the main app.
        panBG = false
        drawOutline = false
        sweep = false
        pulseMarks = false
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView(onFinish: {})
    }
}
