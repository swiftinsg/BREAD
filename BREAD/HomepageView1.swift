// homepage

import SwiftUI
import Foundation

struct StreakPetView: View {
    let potatosize: CGFloat = 200

    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("streakDays") private var streakDays = 0
    @AppStorage("streakPet") private var streakPet = "potato normal"
    @AppStorage("lastStreakIncrease") private var lastStreakIncrease: Double = 0

    private var streakLabel: String {
        streakDays == 1 ? "1 day streak" : "\(streakDays) day streak"
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
                ZStack {
                    Ellipse()
                        .fill(Color.black.opacity(0.08))
                        .frame(width: 220, height: 34)
                        .blur(radius: 12)
                        .offset(y: 112)

                    Image("\(streakPet)")
                        .resizable()
                        .scaledToFit()
                        .offset(x:20)
                        .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)
                }
                .frame(maxWidth: .infinity)
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
        .onAppear(perform: refreshStreak)
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

#Preview {
    StreakPetView()
}
