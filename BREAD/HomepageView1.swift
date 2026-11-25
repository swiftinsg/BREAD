// homepage

import SwiftUI
import UIKit

struct StreakPetView: View {
    let potatosize: CGFloat = 200

    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("streakDays") private var streakDays = 0
    @AppStorage("streakPet") private var streakPet = "potato normal"
    @AppStorage("lastStreakIncrease") private var lastStreakIncrease: Double = 0

    // Petting state
    @State private var isPetting = false
    @State private var petTouchPoint: CGPoint = .zero
    @State private var hearts: [HeartParticle] = []
    @State private var lastHapticTime: TimeInterval = 0
    @State private var lastHapticPoint: CGPoint = .zero
    @State private var isSquishing = false
    @State private var feedback = UIImpactFeedbackGenerator(style: .light)

    private var streakLabel: String {
        streakDays == 1 ? "1 day streak" : "\(streakDays) day streak"
    }

    /// The existing assets are named `potato normal` / `potato happy`, while
    /// other views use `potato` as the base name. Fall back so either works.
    private var happyPetImageName: String {
        let candidate = streakPet == "potato" ? "potato happy" : "\(streakPet) happy"
        return UIImage(named: candidate) != nil ? candidate : "potato happy"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Brand
                VStack(spacing: 2) {
                    Text("Studywich")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(BreadTheme.text)
                }
                .padding(.top, 8)

                Spacer(minLength: 12)

                // Pet with a soft ground shadow so it doesn't float
                GeometryReader { geo in
                    ZStack {
                        Ellipse()
                            .fill(Color.black.opacity(0.08))
                            .frame(width: 220, height: 34)
                            .blur(radius: 12)
                            .offset(y: 112)

                        Image(isPetting ? happyPetImageName : "\(streakPet)")
                            .resizable()
                            .scaledToFit()
                            .offset(x: 20)
                            .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)
                            .scaleEffect(x: isSquishing ? 1.06 : 1,
                                         y: isSquishing ? 0.94 : 1)
                            .animation(.spring(response: 0.24, dampingFraction: 0.5),
                                       value: isSquishing)

                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                    .onChanged { value in
                                        handlePet(at: value.location, in: geo.size)
                                    }
                                    .onEnded { _ in
                                        isPetting = false
                                    }
                            )
                            .overlay {
                                ForEach(hearts) { heart in
                                    FloatingHeartView(heart: heart) { finishedID in
                                        withAnimation(.easeOut(duration: 0.15)) {
                                            hearts.removeAll { $0.id == finishedID }
                                        }
                                    }
                                }

                                if isPetting {
                                    PetHandView(point: petTouchPoint)
                                }
                            }
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 260)
                .accessibilityLabel("Your streak pet")

                Text("I'm hungry...")
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(BreadTheme.secondaryText)
                    .padding(.top, 2)

                // Streak badge — plain text so it stays light on white
                HStack(spacing: 8) {
                    Text("🔥")
                    Text(streakLabel)
                }
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(BreadTheme.text)
                .padding(.top, 12)

                Spacer(minLength: 12)

                NavigationLink {
                    AnalyticsView()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.bar.fill")
                        Text("Analytics")
                    }
                    .frame(maxWidth: .infinity)
                }
                .tint(.orange)
                .padding()
                
                NavigationLink(destination: SelectView2()) {
                    HStack(spacing: 8) {
                        Text("Start Plan")
                        Image(systemName: "arrow.right")
                            .font(.headline.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(BreadPrimaryButtonStyle())
                


                Text("Study to get ingredients and feed Mr Potato!")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(BreadTheme.secondaryText)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .breadBackground()
            .fontDesign(.rounded)
            .tint(BreadTheme.accent)
        }
        .onAppear {
            feedback.prepare()
            refreshStreak()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                refreshStreak()
            }
        }
        // Fires at midnight (and when the calendar day changes) so the
        // streak updates in real time even if the app stays open.
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            refreshStreak()
        }
    }

    /// Petting area is a generous oval around the potato — a near miss counts.
    private func handlePet(at point: CGPoint, in size: CGSize) {
        let center = CGPoint(x: size.width / 2 + 20, y: size.height / 2)
        let dx = (point.x - center.x) / 165
        let dy = (point.y - center.y) / 115

        guard dx * dx + dy * dy <= 1 else {
            isPetting = false
            return
        }

        petTouchPoint = point

        if !isPetting {
            isPetting = true
            pet(in: size)
            return
        }

        // Throttle haptics so a drag feels like gentle strokes, not a buzz.
        let moved = hypot(point.x - lastHapticPoint.x,
                          point.y - lastHapticPoint.y)
        let now = Date().timeIntervalSince1970
        if moved >= 28 || now - lastHapticTime >= 0.22 {
            lastHapticPoint = point
            pet(in: size)
        }
    }

    private func pet(in size: CGSize) {
        lastHapticTime = Date().timeIntervalSince1970

        feedback.impactOccurred()
        feedback.prepare()

        // Hearts escape from around the potato like warm air, not from
        // the finger position.
        spawnHearts(in: size)

        withAnimation(.spring(response: 0.18, dampingFraction: 0.5)) {
            isSquishing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isSquishing = false
            }
        }
    }

    private func spawnHearts(in size: CGSize) {
        let center = CGPoint(x: size.width / 2 + 20, y: size.height / 2)
        let colors: [Color] = [.pink, .red, Color(red: 1, green: 0.55, blue: 0.65)]

        for _ in 0..<3 {
            let angle = CGFloat.random(in: 0...(2 * CGFloat.pi))
            let radius = CGFloat.random(in: 50...95)
            let start = CGPoint(x: center.x + cos(angle) * radius,
                                y: center.y + sin(angle) * radius * 0.65)
            let outward = CGFloat.random(in: 26...66)

            hearts.append(HeartParticle(
                start: start,
                dx: cos(angle) * outward + CGFloat.random(in: -10...10),
                dy: -CGFloat.random(in: 80...140) + sin(angle) * outward * 0.2,
                size: CGFloat.random(in: 11...19),
                color: colors.randomElement() ?? .pink,
                rotation: Double.random(in: -22...22)
            ))
        }

        if hearts.count > 36 {
            hearts.removeFirst(hearts.count - 36)
        }
    }

    /// Resets the streak to 0 if a whole day was missed.
    private func refreshStreak() {
        // Re-read from UserDefaults so a just-finished plan's new streak
        // is reflected even if @AppStorage hasn't propagated yet.
        if let storedDays = UserDefaults.standard.object(forKey: "streakDays") as? Int {
            streakDays = storedDays
        }
        if let storedIncrease = UserDefaults.standard.object(forKey: "lastStreakIncrease") as? Double {
            lastStreakIncrease = storedIncrease
        }
        streakDays = StreakStore.daysAfterCheckingForMissedDay(
            currentDays: streakDays,
            lastIncrease: lastStreakIncrease
        )
    }
}

// MARK: - Original code-drawn petting visuals (no image assets)

private struct HeartParticle: Identifiable {
    let id = UUID()
    let start: CGPoint
    let dx: CGFloat
    let dy: CGFloat
    let size: CGFloat
    let color: Color
    let rotation: Double
}

/// A simple heart path drawn from scratch — no SF Symbol or artwork.
private struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()

        path.move(to: CGPoint(x: w / 2, y: h))
        path.addCurve(to: CGPoint(x: 0, y: h * 0.36),
                      control1: CGPoint(x: w * 0.05, y: h * 0.74),
                      control2: CGPoint(x: 0, y: h * 0.55))
        path.addCurve(to: CGPoint(x: w / 2, y: h * 0.2),
                      control1: CGPoint(x: 0, y: h * 0.1),
                      control2: CGPoint(x: w * 0.25, y: h * 0.05))
        path.addCurve(to: CGPoint(x: w, y: h * 0.36),
                      control1: CGPoint(x: w * 0.75, y: h * 0.05),
                      control2: CGPoint(x: w, y: h * 0.1))
        path.addCurve(to: CGPoint(x: w / 2, y: h),
                      control1: CGPoint(x: w, y: h * 0.55),
                      control2: CGPoint(x: w * 0.95, y: h * 0.74))
        return path
    }
}

private struct FloatingHeartView: View {
    let heart: HeartParticle
    let onFinished: (UUID) -> Void

    @State private var progress: CGFloat = 0
    @State private var isLeaving = false

    var body: some View {
        HeartShape()
            .fill(heart.color)
            .frame(width: heart.size, height: heart.size)
            .shadow(color: heart.color.opacity(0.35), radius: 4, y: 2)
            .rotationEffect(.degrees(heart.rotation * progress))
            .scaleEffect(0.6 + 0.6 * progress)
            // Keep the heart visible from the moment it appears. Fading is a
            // separate step, so it still shows when preview animations are
            // paused or Reduce Motion is on.
            .opacity(isLeaving ? 0 : 0.95)
            .position(x: heart.start.x + heart.dx * progress,
                      y: heart.start.y + heart.dy * progress)
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    progress = 1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isLeaving = true
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
                    onFinished(heart.id)
                }
            }
    }
}

/// An original open hand drawn with SwiftUI shapes. The fingertips sit at
/// the touch point so the hand tracks the finger.
private struct PetHandView: View {
    let point: CGPoint

    private var skin: LinearGradient {
        LinearGradient(
            colors: [Color(red: 1.0, green: 0.88, blue: 0.75),
                     Color(red: 0.96, green: 0.72, blue: 0.55)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private let fingers: [(x: CGFloat, height: CGFloat)] = [
        (-11, 26), (-4, 31), (4, 30), (11, 25)
    ]

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.55))
                .frame(width: 22, height: 22)
                .overlay(Circle().stroke(Color.pink.opacity(0.5), lineWidth: 1.5))
                .position(x: point.x, y: point.y)

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 9)
                    .fill(skin)
                    .frame(width: 30, height: 25)
                    .offset(y: -2)

                ForEach(fingers, id: \.x) { finger in
                    Capsule()
                        .fill(skin)
                        .frame(width: 7, height: finger.height)
                        .offset(x: finger.x, y: -22)
                }

                Capsule()
                    .fill(skin)
                    .frame(width: 8, height: 20)
                    .rotationEffect(.degrees(-55))
                    .offset(x: -17, y: -14)
            }
            .frame(width: 46, height: 56)
            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
            .position(x: point.x, y: point.y + 25)
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    StreakPetView()
}
private struct AnalyticsSandwich: Identifiable, Decodable {
    let id: UUID
    let date: Date
    let ingredientNames: [String]
    let ingredientAssets: [String?]
}

struct AnalyticsView: View {
    @State private var sandwiches = Self.loadSandwiches()

    private static func loadSandwiches() -> [AnalyticsSandwich] {
        guard let data = UserDefaults.standard.data(forKey: "pastSandwiches") else { return [] }
        return (try? JSONDecoder().decode([AnalyticsSandwich].self, from: data)) ?? []
    }

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if sandwiches.isEmpty {
                    ContentUnavailableView {
                        Label("No sandwiches yet", systemImage: "takeoutbag.and.cup.and.straw")
                    } description: {
                        Text("Finish a plan to see your past sandwiches here.")
                    }
                    .padding(.top, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(sandwiches) { sandwich in
                            SandwichCard(sandwich: sandwich)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Analytics")
            .breadBackground()
            .fontDesign(.rounded)
            .tint(BreadTheme.accent)
            .onAppear { sandwiches = Self.loadSandwiches() }
        }
    }
}

private struct SandwichCard: View {
    let sandwich: AnalyticsSandwich

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Image("plate")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .zIndex(0)

                ForEach(Array(sandwich.ingredientAssets.enumerated()), id: \.offset) { item in
                    let index = item.offset
                    if let asset = item.element {
                        Image(asset)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 90)
                            .rotationEffect(.degrees(0))
                            .offset(y: -CGFloat(index) * 8)
                            .zIndex(1)
                    }
                }

                Image("bread up")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .zIndex(2)
            }
            .frame(height: 120)

            Text(Self.dateFormatter.string(from: sandwich.date))
                .font(.caption.weight(.semibold))
                .foregroundStyle(BreadTheme.secondaryText)
                .multilineTextAlignment(.center)

            Text("\(sandwich.ingredientNames.count) ingredient\(sandwich.ingredientNames.count == 1 ? "" : "s")")
                .font(.caption2)
                .foregroundStyle(BreadTheme.text)
        }
        .padding(12)
        .breadCard(cornerRadius: 20, padding: 0)
    }
}

