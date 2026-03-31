//
//  GameHistoryStore.swift
//  Just Euchre iOS
//

import Foundation

struct GameHistoryEntry: Codable, Hashable {
    let date: Date
    let yourScore: Int
    let theirScore: Int
    var wasTrailing: Bool
    var wentToNineNine: Bool

    var didWin: Bool { yourScore > theirScore }

    init(date: Date, yourScore: Int, theirScore: Int, wasTrailing: Bool = false, wentToNineNine: Bool = false) {
        self.date = date
        self.yourScore = yourScore
        self.theirScore = theirScore
        self.wasTrailing = wasTrailing
        self.wentToNineNine = wentToNineNine
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(Date.self, forKey: .date)
        yourScore = try container.decode(Int.self, forKey: .yourScore)
        theirScore = try container.decode(Int.self, forKey: .theirScore)
        wasTrailing = (try? container.decode(Bool.self, forKey: .wasTrailing)) ?? false
        wentToNineNine = (try? container.decode(Bool.self, forKey: .wentToNineNine)) ?? false
    }
}

enum GameHistoryStore {
    static let didChangeNotification = Notification.Name("justeuchre.history.didChange")

    private static let key = "justeuchre.history.entries"
    private static let maxEntries = 365

    static func entries() -> [GameHistoryEntry] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([GameHistoryEntry].self, from: data).sorted(by: { $0.date > $1.date })
        } catch {
            return []
        }
    }

    static func addResult(yourScore: Int, theirScore: Int, wasTrailing: Bool = false, wentToNineNine: Bool = false, date: Date = Date()) {
        var all = entries()
        all.insert(GameHistoryEntry(date: date, yourScore: yourScore, theirScore: theirScore, wasTrailing: wasTrailing, wentToNineNine: wentToNineNine), at: 0)
        if all.count > maxEntries {
            all = Array(all.prefix(maxEntries))
        }
        do {
            let data = try JSONEncoder().encode(all)
            UserDefaults.standard.set(data, forKey: key)
            NotificationCenter.default.post(name: didChangeNotification, object: nil)
        } catch {
            // If encoding fails, just skip persistence.
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }
}
