//
//  BREADApp.swift
//  BREAD
//
//  Created by T Krobot on 11/11/26.
//

import SwiftUI

extension Color {
    static let breadBrown = Color(red: 0.62, green: 0.39, blue: 0.10)
}

@main
struct BREADApp: App {
    var body: some Scene {
        WindowGroup {
            // Launch into the homepage; "Start Plan" pushes the ingredient grid
            // Force light appearance everywhere, regardless of the system setting.
            StreakPetView()
                .tint(BreadTheme.accent)
                .preferredColorScheme(.light)
        }
    }
}
