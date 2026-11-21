// homepage

import SwiftUI
import Foundation

struct StreakPetView: View {
    let potatosize: CGFloat = 200

    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("streakDays") private var streakDays = 0
    @AppStorage("streakPet") private var streakPet = "potato normal"
    @AppStorage("lastStreakIncrease") private var lastStreakIncrease: Double = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                ZStack {
                    Image("\(streakPet)")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 400, height: 1000)
                        .offset(x: 30)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 450)

                Text("I'm hungry...")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.black)
                    .offset(y: -112)

                Text("🔥\(streakDays) Days")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.black)

                NavigationLink(destination: SelectView2()) {
                    Text("Start Plan")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(Color.breadBrown)
                        .cornerRadius(35)
                }
                .padding(.horizontal, 20)

                Text("Study to get ingredients and feed Mr Potato!")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.gray)

                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
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
        streakDays = StreakStore.daysAfterCheckingForMissedDay(
            currentDays: streakDays,
            lastIncrease: lastStreakIncrease
        )
    }
}

#Preview {
    StreakPetView()
}







//
