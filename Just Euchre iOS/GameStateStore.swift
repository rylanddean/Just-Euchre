//
//  GameStateStore.swift
//  Just Euchre iOS
//
//  Persists the in-progress game (today only).
//

import Foundation

enum GameStateStore {
    static let didChangeNotification = Notification.Name("justeuchre.gameState.didChange")

    private static let key = "justeuchre.gameState.payload"

    private struct Payload: Codable {
        let version: Int
        let day: Date
        let savedAt: Date
        let state: Data
    }

    static func save(day: Date, state: Data) {
        let payload = Payload(version: 1, day: day, savedAt: Date(), state: state)
        do {
            let data = try JSONEncoder().encode(payload)
            UserDefaults.standard.set(data, forKey: key)
            NotificationCenter.default.post(name: didChangeNotification, object: nil)
        } catch {
            // Ignore encode failures.
        }
    }

    static func loadIfToday(today: Date) -> Data? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        guard let payload = try? JSONDecoder().decode(Payload.self, from: data) else { return nil }
        guard Calendar.current.isDate(payload.day, inSameDayAs: today) else { return nil }
        return payload.state
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }
}

