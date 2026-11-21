//
//  BREADApp.swift
//  BREAD
//
//  Created by T Krobot on 11/11/26.
//

import SwiftUI

@main
struct BREADApp: App {
    var body: some Scene {
        WindowGroup {
            // Launch into the homepage; "Start Plan" pushes the ingredient grid
            // Force light appearance everywhere, regardless of the system setting.
            StreakPetView()
                .preferredColorScheme(.light)
        }
    }
}
