import Foundation

/// A finished sandwich, stored so the Analytics screen can show past ones.
struct PastSandwich: Identifiable, Codable {
    let id: UUID
    let date: Date
    let ingredientNames: [String]
    let ingredientAssets: [String?]
}

/// Persists past sandwiches in UserDefaults as JSON.
enum SandwichStore {
    private static let key = "pastSandwiches"

    static func load() -> [PastSandwich] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([PastSandwich].self, from: data)) ?? []
    }

    static func save(_ sandwiches: [PastSandwich]) {
        if let data = try? JSONEncoder().encode(sandwiches) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func add(_ sandwich: PastSandwich) {
        var all = load()
        all.insert(sandwich, at: 0)
        if all.count > 50 { all = Array(all.prefix(50)) }
        save(all)
    }
}
