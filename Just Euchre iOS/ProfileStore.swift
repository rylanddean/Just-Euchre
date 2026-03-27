//
//  ProfileStore.swift
//  Just Euchre iOS
//
//  Lightweight profile persistence (name + avatar emoji).
//

import Foundation

enum ProfileStore {
    static let didChangeNotification = Notification.Name("justeuchre.profile.didChange")

    private enum Keys {
        static let name = "justeuchre.profile.name"
        static let emoji = "justeuchre.profile.emoji"
    }

    static var name: String {
        let value = UserDefaults.standard.string(forKey: Keys.name)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (value?.isEmpty == false) ? value! : "You"
    }

    static var emoji: String {
        let value = UserDefaults.standard.string(forKey: Keys.emoji)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (value?.isEmpty == false) ? value! : "🙂"
    }

    static func save(name: String, emoji: String) {
        UserDefaults.standard.set(name, forKey: Keys.name)
        UserDefaults.standard.set(emoji, forKey: Keys.emoji)
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: Keys.name)
        UserDefaults.standard.removeObject(forKey: Keys.emoji)
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }
}
