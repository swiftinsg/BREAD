//
//  ChooseView3.swift
//  BREAD
//
//  Created by T Krobot on 11/11/26.
//

import SwiftUI

struct Topping: Identifiable, Codable {
    let name: String
    var icon: String? = nil
    var assetName: String? = nil
    var rotated = false
    var id: String { name }
}

/// An ingredient the user added to a plan, with their own name and study time.
struct PlanIngredient: Identifiable, Codable {
    let id = UUID()
    let topping: Topping
    var name: String
    var hours: Int
    var minutes: Int
}

struct ChooseView3: View {
    /// Called with the finished ingredient when the user taps "Add".
    var onAddIngredient: (PlanIngredient) -> Void = { _ in }
    @Environment(\.dismiss) private var dismiss

    let toppings: [Topping] = [
        Topping(name: "Lettuce", assetName: "lettuce i"),
        Topping(name: "Tomato", assetName: "tomato i"),
        Topping(name: "Cheese", assetName: "cheese i"),
        Topping(name: "Salami", assetName: "salami i"),
        Topping(name: "Bacon", assetName: "bacon i"),
        Topping(name: "Ham", assetName: "ham i"),
        Topping(name: "Chicken cutlet", assetName: "chicken cutlet i"),
        Topping(name: "Chicken bits", assetName: "chicken bits i"),
        Topping(name: "Cucumber", assetName: "cucumber i"),
        Topping(name: "Pickle (cut vertically)", assetName: "Pickle (cut vertically) i"),
        Topping(name: "Pickle (cut horizontally)", assetName:"Pickle (cut horizontally) i"),
        Topping(name: "Turkey", assetName: "turkey i"),
        Topping(name: "Mayo", assetName: "mayo i"),
        Topping(name: "Beef", assetName: "beef i"),
        Topping(name: "Cheese slice", assetName: "cheese slice i"),
        Topping(name: "Mozzarella cheese ball", assetName: "Mozzarella cheese ball i"),
        Topping(name: "Corn", assetName: "corn i"),
        Topping(name: "White mushroom", assetName: "white mushroom i"),
        Topping(name: "Brown mushroom", assetName: "brown mushroom i"),
        Topping(name: "Onion", assetName: "onion i"),
    ]
    
    @State private var selectedTopping: Topping?
    // Set when "Add" is tapped so the whole picker (not just the sheet) closes
    @State private var shouldDismissAfterSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                CircleIconButton(systemName: "arrow.left") {
                    dismiss()
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)

            VStack(alignment: .leading, spacing: 4) {
                Text("Pick your toppings")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(BreadTheme.text)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)

            // 2-by-2 grid of toppings
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                ], spacing: 16) {
                    ForEach(toppings) { topping in
                        Button {
                            selectedTopping = topping
                        } label: {
                            VStack(spacing: 8) {
                                // Square image with a curved border
                                Rectangle()
                                    .fill(BreadTheme.surface)
                                    .aspectRatio(1, contentMode: .fit)
                                    .overlay {
                                        if let assetName = topping.assetName {
                                            Image(assetName)
                                                .resizable()
                                                .scaledToFit()
                                                .padding(16)
                                                .rotationEffect(.degrees(topping.rotated ? 90 : 0))
                                        } else if let icon = topping.icon {
                                            Text(icon)
                                                .font(.system(size: 60))
                                                .rotationEffect(.degrees(topping.rotated ? 90 : 0))
                                        }
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .strokeBorder(BreadTheme.stroke, lineWidth: 1)
                                    }
                                    .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
                                
                                Text(topping.name)
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(BreadTheme.text)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .background(BreadAmbientBackground())
        .fontDesign(.rounded)
        .tint(BreadTheme.accent)
        .sheet(item: $selectedTopping, onDismiss: {
            // After the sheet closes, also close the picker to return to SelectView2
            if shouldDismissAfterSheet {
                shouldDismissAfterSheet = false
                dismiss()
            }
        }) { topping in
            ToppingDetailSheet(topping: topping) { ingredient in
                onAddIngredient(ingredient)
                shouldDismissAfterSheet = true
            }
        }
    }
}

struct ToppingDetailSheet: View {
    let topping: Topping
    /// Called with the finished ingredient when the user taps "Add".
    var onAdd: (PlanIngredient) -> Void = { _ in }
    @Environment(\.dismiss) private var dismiss

    @State private var nameInput: String = ""
    @State private var hours: Int = 0
    @State private var minutes: Int = 0

    /// A name must be typed and the time must be at least one minute
    private var canAdd: Bool {
        let trimmedName = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && (hours * 60 + minutes) > 0
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            // Main content: Image + bold name on left, native inputs on right
            HStack(alignment: .center, spacing: 16) {
                // Left side: Topping image with bold ingredient name underneath
                VStack(spacing: 8) {
                    if let assetName = topping.assetName {
                        Image(assetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 110, height: 110)
                            .rotationEffect(.degrees(topping.rotated ? 90 : 0))
                    } else if let icon = topping.icon {
                        Text(icon)
                            .font(.system(size: 72))
                            .rotationEffect(.degrees(topping.rotated ? 90 : 0))
                    }

                    Text(topping.name)
                        .font(.headline.bold())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)

                // Right side: Native Apple inputs on white sheet
                VStack(spacing: 12) {
                    // Native iOS TextField with grey "type here" placeholder
                    TextField(
                        "",
                        text: $nameInput,
                        prompt: Text("What are we working on today?").foregroundStyle(BreadTheme.secondaryText)
                    )
                    .font(.body.weight(.medium))
                    .foregroundStyle(BreadTheme.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(
                        BreadTheme.field,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(BreadTheme.stroke, lineWidth: 1)
                    }

                    // Native iOS Duration Picker (h : m)
                    HStack(spacing: 4) {
                        Picker("Hours", selection: $hours) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text("\(hour)").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 50, height: 80)
                        .clipped()

                        Text("h")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(":")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 2)

                        Picker("Minutes", selection: $minutes) {
                            ForEach(0..<60, id: \.self) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 45, height: 80)
                        .clipped()

                        Text("min")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .background(
                        BreadTheme.field,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)

            Spacer()

            // Primary glass pill, same as the rest of the app
            Button {
                let trimmedName = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
                let ingredient = PlanIngredient(
                    topping: topping,
                    name: trimmedName,
                    hours: hours,
                    minutes: minutes
                )
                // Add closes the sheet, then closes the picker back to SelectView2
                onAdd(ingredient)
                dismiss()
            } label: {
                Text("Add")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(BreadPrimaryButtonStyle(enabled: canAdd))
            .disabled(!canAdd)
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .presentationBackground(BreadTheme.surface)
        .presentationDetents([.fraction(0.45), .medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    ChooseView3()
}

