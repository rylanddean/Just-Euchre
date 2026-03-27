//
//  GameHistoryStore.swift
//  Just Euchre iOS
//

import Foundation

struct GameHistoryEntry: Codable, Hashable {
    let date: Date
    let yourScore: Int
    let theirScore: Int

    var didWin: Bool { yourScore > theirScore }
}

enum GameHistoryStore {
    static let didChangeNotification = Notification.Name("justeuchre.history.didChange")

    private static let key = "justeuchre.history.entries"
    private static let maxEntries = 30

    static func entries() -> [GameHistoryEntry] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([GameHistoryEntry].self, from: data).sorted(by: { $0.date > $1.date })
        } catch {
            return []
        }
    }

    static func addResult(yourScore: Int, theirScore: Int, date: Date = Date()) {
        var all = entries()
        all.insert(GameHistoryEntry(date: date, yourScore: yourScore, theirScore: theirScore), at: 0)
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
