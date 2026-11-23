//
//  Theme.swift
//  BREAD
//
//  Adaptive system surfaces with warm accents and shared glass styling.
//

import SwiftUI
import UIKit

enum BreadTheme {
    /// Semantic system colors adapt automatically to light and dark appearance.
    static let background = Color(uiColor: .systemBackground)
    static let surface = Color(uiColor: .secondarySystemBackground)
    static let field = Color(uiColor: .tertiarySystemBackground)
    static let text = Color(uiColor: .label)
    static let secondaryText = Color(uiColor: .secondaryLabel)
    static let stroke = Color(uiColor: .separator)

    /// Warm coral — primary buttons and highlights.
    static let accent = Color(red: 0.95, green: 0.42, blue: 0.18)
    /// Deeper coral in light mode and a brighter coral in dark mode.
    static let accentDeep = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 1.00, green: 0.62, blue: 0.38, alpha: 1)
            : UIColor(red: 0.76, green: 0.28, blue: 0.08, alpha: 1)
    })
    /// Selected-state fill tuned for each appearance.
    static let accentSoft = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.30, green: 0.17, blue: 0.12, alpha: 1)
            : UIColor(red: 1.00, green: 0.93, blue: 0.88, alpha: 1)
    })
    static let muted = Color(uiColor: .systemGray3)
    static let success = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.35, green: 0.78, blue: 0.48, alpha: 1)
            : UIColor(red: 0.18, green: 0.52, blue: 0.31, alpha: 1)
    })
}

/// System-adaptive canvas with subtle warm glows behind Liquid Glass controls.
struct BreadAmbientBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    private var glowOpacity: Double {
        colorScheme == .dark ? 0.04 : 0.12
    }

    var body: some View {
        ZStack {
            BreadTheme.background

            GeometryReader { proxy in
                Circle()
                    .fill(Color(red: 1.00, green: 0.72, blue: 0.50))
                    .frame(width: proxy.size.width)
                    .blur(radius: 110)
                    .opacity(glowOpacity)
                    .offset(
                        x: -proxy.size.width * 0.5,
                        y: -proxy.size.height * 0.48
                    )

                Circle()
                    .fill(Color(red: 1.00, green: 0.84, blue: 0.64))
                    .frame(width: proxy.size.width * 0.9)
                    .blur(radius: 120)
                    .opacity(glowOpacity)
                    .offset(
                        x: proxy.size.width * 0.55,
                        y: proxy.size.height * 0.02
                    )

                Circle()
                    .fill(Color(red: 0.99, green: 0.66, blue: 0.56))
                    .frame(width: proxy.size.width * 0.7)
                    .blur(radius: 130)
                    .opacity(glowOpacity * 0.6)
                    .offset(
                        x: -proxy.size.width * 0.2,
                        y: proxy.size.height * 0.62
                    )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

/// Rounded, softly shadowed card used for content blocks.
private struct BreadCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                BreadTheme.surface,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(BreadTheme.stroke.opacity(0.7), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 6)
    }
}

extension View {
    func breadCard(cornerRadius: CGFloat = 24, padding: CGFloat = 0) -> some View {
        modifier(BreadCardModifier(cornerRadius: cornerRadius, padding: padding))
    }

    /// Adaptive page background used on every screen.
    func breadBackground() -> some View {
        background(BreadAmbientBackground())
    }
}

/// Full-width primary pill used for Start / Complete / Feed / Done.
struct BreadPrimaryButtonStyle: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 58)
            .glassEffect(
                enabled
                    ? Glass.regular.tint(BreadTheme.accent).interactive()
                    : Glass.regular.tint(BreadTheme.muted).interactive(),
                in: Capsule()
            )
            .shadow(
                color: enabled ? BreadTheme.accentDeep.opacity(0.22) : .clear,
                radius: 12,
                x: 0,
                y: 6
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
