import SwiftUI

struct AnalyticsView: View {
    @State private var sandwiches: [PastSandwich] = SandwichStore.load()

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if sandwiches.isEmpty {
                    ContentUnavailableView {
                        Label("No sandwiches yet", systemImage: "takeoutbag.and.cup.and.straw")
                    } description: {
                        Text("Finish a plan to see your past sandwiches here.")
                    }
                    .padding(.top, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(sandwiches) { sandwich in
                            SandwichCard(sandwich: sandwich)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Analytics")
            .breadBackground()
            .fontDesign(.rounded)
            .tint(BreadTheme.accent)
            .onAppear { sandwiches = SandwichStore.load() }
        }
    }
}

private struct SandwichCard: View {
    let sandwich: PastSandwich

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(spacing: 10) {
            // Mini sandwich artwork
            ZStack {
                Image("plate")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .zIndex(0)

                ForEach(Array(sandwich.ingredientAssets.enumerated()), id: \.offset) { index, asset in
                    if let asset {
                        Image(asset)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 90)
                            .rotationEffect(.degrees(0))
                            .offset(y: -CGFloat(index) * 8)
                            .zIndex(1)
                    }
                }

                Image("bread up")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .zIndex(2)
            }
            .frame(height: 120)

            Text(Self.dateFormatter.string(from: sandwich.date))
                .font(.caption.weight(.semibold))
                .foregroundStyle(BreadTheme.secondaryText)
                .multilineTextAlignment(.center)

            Text("\(sandwich.ingredientNames.count) ingredient\(sandwich.ingredientNames.count == 1 ? "" : "s")")
                .font(.caption2)
                .foregroundStyle(BreadTheme.text)
        }
        .padding(12)
        .breadCard(cornerRadius: 20, padding: 0)
    }
}

#Preview {
    AnalyticsView()
}
