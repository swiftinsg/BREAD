import SwiftUI

struct SelectView2: View {
    @Environment(\.dismiss) private var dismiss

    @State private var ingredients: [PlanIngredient] = []
    @State private var showChooseView3 = false
    /// Ingredient whose detail sheet is currently open
    @State private var selectedIngredient: PlanIngredient?
    @State private var showTimer = false
    /// Set when the flow finishes so we pop back to the homepage
    @State private var shouldReturnHome = false
    /// Timer state lives here so dismissing and re-opening TimerView5
    /// keeps each ingredient's remaining time instead of resetting it
    @State private var timerState: [UUID: IngredientTimer] = [:]
    @State private var droppedOrder: [UUID] = []
    @State private var selectedIngredientID: UUID?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]
    
    var body: some View {
        VStack {
            // Buttons live in the view itself, not in the navigation bar, so
            // they stay visible even if the toolbar/nav bar is hidden.
            HStack {
                CircleIconButton(systemName: "arrow.left", filled: false) {
                    dismiss()
                }

                Spacer()

                CircleIconButton(systemName: "plus", filled: true) {
                    showChooseView3 = true
                }
            }
            .padding(.horizontal)

            // Ingredients added from ChooseView3
            if ingredients.isEmpty {
                ContentUnavailableView {
                    Label("No Ingredients Yet", systemImage: "takeoutbag.and.cup.and.straw")
                } description: {
                    Text("Click the + button to add ingredients in your studywich!")
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(ingredients) { ingredient in
                            IngredientCell(
                                ingredient: ingredient,
                                onSelect: { selectedIngredient = ingredient },
                                onDelete: { ingredients.removeAll { $0.id == ingredient.id } }
                            )
                        }
                    }
                    .padding()
                }
            }
            
            Button {
                showTimer = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                    Text("START")
                }
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .tint(ingredients.isEmpty ? BreadTheme.muted : BreadTheme.accent)
            .disabled(ingredients.isEmpty)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(BreadAmbientBackground())
        .fontDesign(.rounded)
        .tint(BreadTheme.accent)
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(isPresented: $showChooseView3) {
            ChooseView3 { ingredient in
                ingredients.append(ingredient)
            }
        }
        .fullScreenCover(isPresented: $showTimer, onDismiss: {
            // Once the timer cover has closed, pop back to HomepageView1
            if shouldReturnHome {
                shouldReturnHome = false
                dismiss()
            }
        }) {
            TimerView5(
                ingredients: ingredients,
                selectedID: Binding(
                    get: { selectedIngredientID ?? ingredients.first?.id ?? UUID() },
                    set: { selectedIngredientID = $0 }
                ),
                onFinishPlan: {
                    shouldReturnHome = true
                    showTimer = false
                },
                timers: $timerState,
                droppedOrder: $droppedOrder
            )
        }
        .sheet(item: $selectedIngredient) { ingredient in
            // Bind straight into the array so edits show up in the grid instantly
            if let index = ingredients.firstIndex(where: { $0.id == ingredient.id }) {
                IngredientDetailSheet(ingredient: $ingredients[index])
            }
        }
    }
}

/// Small circular icon button used in screen headers.
struct CircleIconButton: View {
    let systemName: String
    var filled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.headline.weight(.bold))
                .foregroundStyle(BreadTheme.accentDeep)
                .frame(width: 44, height: 44)
                .glassEffect(
                    filled
                        ? Glass.regular
                            .tint(BreadTheme.accent.opacity(0.30))
                            .interactive()
                        : Glass.regular.interactive(),
                    in: Circle()
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

/// One added ingredient: the picture plus the name typed in ChooseView3.
struct IngredientCell: View {
    let ingredient: PlanIngredient
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Button(action: onSelect) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(BreadTheme.surface)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            if let assetName = ingredient.topping.assetName {
                                Image(assetName)
                                    .resizable()
                                    .scaledToFit()
                                    .padding(16)
                                    .rotationEffect(.degrees(ingredient.topping.rotated ? 90 : 0))
                            } else if let icon = ingredient.topping.icon {
                                Text(icon)
                                    .font(.system(size: 60))
                                    .rotationEffect(.degrees(ingredient.topping.rotated ? 90 : 0))
                            }
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(BreadTheme.stroke, lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(Color.red))
                }
                .offset(x: 10, y: -10)
            }
            
            Text(ingredient.name)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(BreadTheme.text)
        }
    }
}

/// Detail sheet for an added ingredient: picture on the left, editable name
/// and study time on the right. Edits update the ingredient in SelectView2.
struct IngredientDetailSheet: View {
    @Binding var ingredient: PlanIngredient

    var body: some View {
            HStack(alignment: .center, spacing: 20) {
                // Ingredient picture
                Color.clear
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        if let assetName = ingredient.topping.assetName {
                            Image(assetName)
                                .resizable()
                                .scaledToFit()
                                .padding(16)
                                .rotationEffect(.degrees(ingredient.topping.rotated ? 90 : 0))
                        } else if let icon = ingredient.topping.icon {
                            Text(icon)
                                .font(.system(size: 60))
                                .rotationEffect(.degrees(ingredient.topping.rotated ? 90 : 0))
                        }
                    }
                    .frame(maxWidth: .infinity)

            VStack(spacing: 16) {
                // Name (editable, updates the grid instantly)
                TextField(
                    "",
                    text: $ingredient.name,
                    prompt: Text("name").foregroundStyle(BreadTheme.secondaryText)
                )
                .font(.body.weight(.medium))
                .foregroundStyle(BreadTheme.text)
                .multilineTextAlignment(.center)
                .padding(.vertical, 14)
                .padding(.horizontal, 12)
                .background(
                    BreadTheme.field,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(BreadTheme.stroke, lineWidth: 1)
                }

                // Study time chosen in ChooseView3, shown read-only as XX h : XX m
                Text("\(ingredient.hours) h : \(ingredient.minutes) m")
                    .font(.title3)
                    .foregroundStyle(BreadTheme.text)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        BreadTheme.field,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(BreadTheme.stroke, lineWidth: 1)
                    }

            }
            .frame(maxWidth: .infinity)
        }
        .padding(24)
        .presentationBackground(.white)
        .presentationDetents([.fraction(0.4), .medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    NavigationStack {
        SelectView2()
    }
}
