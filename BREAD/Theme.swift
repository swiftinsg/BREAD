//
//  Theme.swift
//  BREAD
//
//  Clean white base with warm accents, plus shared card and glass styling
//  so every screen feels like one app.
//

import SwiftUI

enum BreadTheme {
    /// White page background
    static let background = Color.white
    /// Cards, sheets and raised surfaces
    static let surface = Color.white
    /// Slightly grey fill for text fields sitting on white
    static let field = Color(red: 0.96, green: 0.96, blue: 0.97)
    /// Near-black — primary text
    static let text = Color(red: 0.10, green: 0.10, blue: 0.12)
    /// Grey — captions and labels
    static let secondaryText = Color(red: 0.42, green: 0.42, blue: 0.46)
    /// Warm coral — primary buttons and highlights
    static let accent = Color(red: 0.95, green: 0.42, blue: 0.18)
    /// Deeper coral for text on soft accents and button shadows
    static let accentDeep = Color(red: 0.76, green: 0.28, blue: 0.08)
    /// Pale peach for badges and selected states
    static let accentSoft = Color(red: 1.00, green: 0.93, blue: 0.88)
    /// Hairline card outlines
    static let stroke = Color(red: 0.90, green: 0.90, blue: 0.92)
    /// Disabled controls
    static let muted = Color(red: 0.78, green: 0.78, blue: 0.80)
    /// Ready / success green
    static let success = Color(red: 0.22, green: 0.62, blue: 0.38)
}

/// White canvas with a few very soft warm glows. Keeps the app white while
/// giving the Liquid Glass controls something to refract.
struct BreadAmbientBackground: View {
    var body: some View {
        ZStack {
            Color.white

            GeometryReader { proxy in
                Circle()
                    .fill(Color(red: 1.00, green: 0.72, blue: 0.50))
                    .frame(width: proxy.size.width)
                    .blur(radius: 110)
                    .opacity(0.12)
                    .offset(
                        x: -proxy.size.width * 0.5,
                        y: -proxy.size.height * 0.48
                    )

                Circle()
                    .fill(Color(red: 1.00, green: 0.84, blue: 0.64))
                    .frame(width: proxy.size.width * 0.9)
                    .blur(radius: 120)
                    .opacity(0.12)
                    .offset(
                        x: proxy.size.width * 0.55,
                        y: proxy.size.height * 0.02
                    )

                Circle()
                    .fill(Color(red: 0.99, green: 0.66, blue: 0.56))
                    .frame(width: proxy.size.width * 0.7)
                    .blur(radius: 130)
                    .opacity(0.07)
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
                    .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 6)
    }
}

extension View {
    func breadCard(cornerRadius: CGFloat = 24, padding: CGFloat = 0) -> some View {
        modifier(BreadCardModifier(cornerRadius: cornerRadius, padding: padding))
    }

    /// White page background used on every screen.
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
