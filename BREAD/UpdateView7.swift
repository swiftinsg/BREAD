//
//  Untitled.swift
//  BREAD
//
//  Created by T Krobot on 11/11/26.
//

import SwiftUI
import UIKit
import AVFoundation

struct UpdateView7: View {
    let petSize: CGFloat = 200
    let sandwichSize: CGFloat = 100
    let totalBites = 4
    var ingredients: [PlanIngredient] = []

    let onDone: () -> Void

    @AppStorage("streakDays") private var streakDays = 0
    @AppStorage("streakPet") private var streakPet = "potato"
    /// When the streak was last increased (seconds since 1970).
    /// Used so finishing the plan more than once in a day only counts once.
    @AppStorage("lastStreakIncrease") private var lastStreakIncrease: Double = 0

    @State private var bitesTaken = 0
    @State private var isChomping = false
    @State private var hasGulped = false
    @State private var petStatus = "eat"
    /// Small head wiggle while chewing
    @State private var chompRotation: Double = 0
    /// Tiny pop on the sandwich with every bite
    @State private var sandwichPop = false
    /// Happy hop after the last bite
    @State private var happyHop = false
    /// Streak pill bounce when it updates
    @State private var badgePulse = false
    /// Prevents the feeding task from being started twice by repeated onAppear
    @State private var hasStartedFeeding = false
    /// True once the streak has actually been updated, so Done can't be tapped early
    // Completion is recorded as soon as the feeding screen appears.
    /// Shown when finishing again on a day the streak was already counted
    @State private var showDailyLimitAlert = false
    @State private var eatingSoundPlayer: AVAudioPlayer?
    var sandwichLeft: CGFloat {
        CGFloat(totalBites - bitesTaken) / CGFloat(totalBites)
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 0)

            Text(petStatus == "happy" ? "Yum!" : (hasStartedFeeding ? "Nom nom nom..." : "Enjoy!"))

                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(BreadTheme.text)
                .scaleEffect(petStatus == "happy" ? 1.08 : 1)
                .animation(.spring(response: 0.35, dampingFraction: 0.5), value: petStatus)

            HStack(spacing: 12) {
                Image("\(streakPet) \(petStatus)")
                    .resizable()
                    .scaledToFit()
                    .frame(width: petSize, height: petSize)
                    .scaleEffect(x: isChomping ? 1.15 : 1,
                                 y: isChomping ? 0.75 : 1,
                                 anchor: .bottom)
                    .rotationEffect(.degrees(chompRotation))
                    .scaleEffect(hasGulped ? 1.15 : 1)
                    .offset(x: isChomping ? 14 : 0)
                    .offset(y: happyHop ? -14 : 0)
                    .animation(.interpolatingSpring(stiffness: 200, damping: 9), value: happyHop)
                    .overlay(alignment: .topTrailing) {

                        
                    }
                
                sandwichStack
                    .frame(width: sandwichSize, height: sandwichSize)
                    .scaleEffect(sandwichPop ? 1.08 : 1)
                    .animation(.spring(response: 0.22, dampingFraction: 0.45), value: sandwichPop)
                    .mask {
                        Rectangle()
                            .scaleEffect(x: sandwichLeft, anchor: .trailing)
                    }
                    .offset(x: -67 * CGFloat(bitesTaken))
            }
            .padding(20)
            

            HStack(spacing: 8) {
                Text("🔥")
                Text(streakDays == 1 ? "1 day streak" : "\(streakDays) day streak")
            }
            .font(.system(.headline, design: .rounded).weight(.semibold))
            .foregroundStyle(BreadTheme.text)
            .scaleEffect(badgePulse ? 1.12 : 1)
            .animation(.spring(response: 0.32, dampingFraction: 0.45), value: badgePulse)

            Spacer(minLength: 0)

            // Same glass pill styling as the "Start Plan" button on HomepageView1
            Button {
                onDone()
            } label: {
                HStack(spacing: 8) {
                    Text("Done")
                    Image(systemName: "checkmark")
                        .font(.headline.weight(.bold))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(BreadPrimaryButtonStyle())
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .breadBackground()
        .fontDesign(.rounded)
        .tint(BreadTheme.accent)
        // Hide the navigation bar so no back arrow shows while feeding
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            feedThePotato()
        }
        .onDisappear {
            eatingSoundPlayer?.stop()
        }
        .alert("ALERT", isPresented: $showDailyLimitAlert) {
            Button("Okay", role: .cancel) { }
        } message: {
            Text("Streak already increased today.")
        }
    }

    private func playEatingSound() {
        guard let soundURL = Bundle.main.url(
            forResource: "freesound_community-eating-chips-70602-[AudioTrimmer.com]",
            withExtension: "mp3"
        ) else { return }

        do {
            let player = try AVAudioPlayer(contentsOf: soundURL)
            player.prepareToPlay()
            eatingSoundPlayer = player
            player.play()
        } catch {
            eatingSoundPlayer = nil
        }
    }

    func feedThePotato() {
        guard !hasStartedFeeding else { return }
        hasStartedFeeding = true

        // Count the streak as soon as the plan is finished, rather than after
        // the feeding animation, so tapping "Done" early can't skip it.
        let updatedStreak = StreakStore.registerCompletion(
            currentDays: streakDays,
            lastIncrease: lastStreakIncrease
        )
        streakDays = updatedStreak.days
        lastStreakIncrease = updatedStreak.lastIncrease
        let alreadyCountedToday = updatedStreak.alreadyCountedToday

        Task {
            let remainingBites = totalBites - bitesTaken
            let chompHaptic = UIImpactFeedbackGenerator(style: .medium)
            chompHaptic.prepare()

            for bite in 0..<remainingBites {
                // Lean in, open wide, and show the "Nom!" bubble
                withAnimation(.easeOut(duration: 0.12)) {
                    isChomping = true
                    chompRotation = bite.isMultiple(of: 2) ? -4 : 4
                }
                chompHaptic.impactOccurred(intensity: min(1.0, 0.45 + 0.18 * Double(bite)))
                try? await Task.sleep(for: .milliseconds(120))

                // Play the sound as the first bite lands.
                if bite == 0 {
                    playEatingSound()
                }

                // Chomp: take the bite, pop the sandwich, then spring back
                withAnimation(.spring(response: 0.26, dampingFraction: 0.5)) {
                    bitesTaken += 1
                    sandwichPop = true
                }
                try? await Task.sleep(for: .milliseconds(90))

                withAnimation(.easeOut(duration: 0.14)) {
                    isChomping = false
                    chompRotation = 0
                    sandwichPop = false
                }
                try? await Task.sleep(for: .milliseconds(330))
            }

            // Gulp and switch to the happy pose
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.interpolatingSpring(stiffness: 150, damping: 7)) {
                hasGulped = true
                petStatus = "happy"
            }

            // Streak pill bounces
            withAnimation(.spring(response: 0.32, dampingFraction: 0.45)) {
                badgePulse = true
            }

            // Two happy little hops
            try? await Task.sleep(for: .milliseconds(140))
            withAnimation(.interpolatingSpring(stiffness: 220, damping: 9)) { happyHop = true }
            try? await Task.sleep(for: .milliseconds(170))
            withAnimation(.interpolatingSpring(stiffness: 220, damping: 9)) { happyHop = false }
            try? await Task.sleep(for: .milliseconds(120))
            withAnimation(.interpolatingSpring(stiffness: 220, damping: 9)) { happyHop = true }
            try? await Task.sleep(for: .milliseconds(150))
            withAnimation(.interpolatingSpring(stiffness: 220, damping: 9)) { happyHop = false }

            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                badgePulse = false
            }
            

            // Feeding is done, so the Done button can be enabled.
            // The streak itself was already registered when feeding began.
            // The completion is already recorded above.

            // Let the user know why the number didn't change
            if alreadyCountedToday {
                showDailyLimitAlert = true
            }
        }
    }

    // MARK: - Sandwich

    @ViewBuilder
    private var sandwichStack: some View {
        VStack(spacing: -40) {
            Image("bread up")
                .resizable()
                .scaledToFit()
                .zIndex(1)

            Image("bread up")
                .resizable()
                .scaledToFit()
                .zIndex(0)

        }
    }


    @ViewBuilder
    private func updateIngredientView(for ingredient: PlanIngredient) -> some View {
        if let assetName = updateAssetName(for: ingredient.topping) {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: sandwichSize * 0.6, height: sandwichSize * 0.6)
                .rotationEffect(.degrees(ingredient.topping.rotated ? 90 : 0))
        } else if let icon = ingredient.topping.icon {
            Text(icon)
                .font(.system(size: sandwichSize * 0.4))
        }
    }

    private func updateAssetName(for topping: Topping) -> String? {
        guard let name = topping.assetName else { return nil }
        guard name.hasSuffix(" i") else { return name }

        let smallName = String(name.dropLast(2)) + " s"
        if UIImage(named: smallName) != nil {
            return smallName
        }
        if UIImage(named: smallName + " ") != nil {
            return smallName + " "
        }
        return name
    }
}

#Preview {
    UpdateView7(onDone: {})
}
