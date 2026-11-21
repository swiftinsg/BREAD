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
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.body)
                        .foregroundStyle(.blue)
                        .frame(width: 40, height: 40)
                        .glassEffect(.regular, in: Circle())
                        .overlay {
                            Circle()
                                .strokeBorder(Color.gray.opacity(0.4), lineWidth: 1)
                        }
                        .contentShape(Circle())
                }

                Spacer()

                Button {
                    showChooseView3 = true
                } label: {
                    Image(systemName: "plus")
                        .padding(5)
                        .glassEffect()
                        .font(.title3.bold())
                        .foregroundStyle(.blue)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
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
                Text("START")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(ingredients.isEmpty ? Color.gray : Color.brown)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(ingredients.isEmpty ? Color.gray : Color.brown, lineWidth: 4)
                    }
            }
            .disabled(ingredients.isEmpty)
            .padding()
        }
        .background(Color.white)
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

/// One added ingredient: the picture plus the name typed in ChooseView3.
struct IngredientCell: View {
    let ingredient: PlanIngredient
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Button(action: onSelect) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
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
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.gray.opacity(0.5), lineWidth: 2)
                        }
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
                .foregroundStyle(.black)
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
                    prompt: Text("name").foregroundStyle(.gray)
                )
                .font(.title3)
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
                .padding(.vertical, 18)
                .padding(.horizontal, 12)

                // Study time chosen in ChooseView3, shown read-only as XX h : XX m
                Text("\(ingredient.hours) h : \(ingredient.minutes) m")
                    .font(.title3)
                    .foregroundStyle(.black)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)

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
