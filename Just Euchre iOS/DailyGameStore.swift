//
//  DailyGameStore.swift
//  Just Euchre iOS
//
//  One-game-per-day gate + streak tracking.
//

import Foundation

enum DailyGameStore {
    static let didChangeNotification = Notification.Name("justeuchre.daily.didChange")

    private enum Keys {
        static let startedDay = "justeuchre.daily.startedDay" // Date at start-of-day
        static let completedDay = "justeuchre.daily.completedDay" // Date at start-of-day
        static let lastCompletionDay = "justeuchre.daily.lastCompletionDay" // Date at start-of-day
        static let currentStreak = "justeuchre.daily.currentStreak"
        static let longestStreak = "justeuchre.daily.longestStreak"
        static let longestStreakDate = "justeuchre.daily.longestStreakDate" // Date at start-of-day
    }

    static func todayKeyDate(now: Date = Date()) -> Date {
        Calendar.current.startOfDay(for: now)
    }

    static func hasStartedToday(now: Date = Date()) -> Bool {
        let today = todayKeyDate(now: now)
        guard let started = UserDefaults.standard.object(forKey: Keys.startedDay) as? Date else { return false }
        return Calendar.current.isDate(started, inSameDayAs: today)
    }

    static func isCompletedToday(now: Date = Date()) -> Bool {
        let today = todayKeyDate(now: now)
        guard let completed = UserDefaults.standard.object(forKey: Keys.completedDay) as? Date else { return false }
        return Calendar.current.isDate(completed, inSameDayAs: today)
    }

    static func canStartNewGameToday(now: Date = Date()) -> Bool {
        !hasStartedToday(now: now)
    }

    static func markStartedToday(now: Date = Date()) {
        let today = todayKeyDate(now: now)
        UserDefaults.standard.set(today, forKey: Keys.startedDay)
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }

    static func markCompletedToday(now: Date = Date()) {
        let today = todayKeyDate(now: now)
        if isCompletedToday(now: now) { return }

        let defaults = UserDefaults.standard
        let lastCompletion = defaults.object(forKey: Keys.lastCompletionDay) as? Date
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)

        var current = defaults.integer(forKey: Keys.currentStreak)
        if let lastCompletion, let yesterday, Calendar.current.isDate(lastCompletion, inSameDayAs: yesterday) {
            current += 1
        } else {
            current = 1
        }

        defaults.set(today, forKey: Keys.completedDay)
        defaults.set(today, forKey: Keys.lastCompletionDay)
        defaults.set(current, forKey: Keys.currentStreak)

        let longest = defaults.integer(forKey: Keys.longestStreak)
        if current > longest {
            defaults.set(current, forKey: Keys.longestStreak)
            defaults.set(today, forKey: Keys.longestStreakDate)
        }

        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }

    static var longestStreak: Int {
        UserDefaults.standard.integer(forKey: Keys.longestStreak)
    }

    static var currentStreak: Int {
        UserDefaults.standard.integer(forKey: Keys.currentStreak)
    }

    static var longestStreakDate: Date? {
        UserDefaults.standard.object(forKey: Keys.longestStreakDate) as? Date
    }

    // MARK: - Developer utilities

    static func debugResetToday(now: Date = Date()) {
        let today = todayKeyDate(now: now)
        let defaults = UserDefaults.standard

        if let started = defaults.object(forKey: Keys.startedDay) as? Date, Calendar.current.isDate(started, inSameDayAs: today) {
            defaults.removeObject(forKey: Keys.startedDay)
        }
        if let completed = defaults.object(forKey: Keys.completedDay) as? Date, Calendar.current.isDate(completed, inSameDayAs: today) {
            defaults.removeObject(forKey: Keys.completedDay)
        }
        if let last = defaults.object(forKey: Keys.lastCompletionDay) as? Date, Calendar.current.isDate(last, inSameDayAs: today) {
            defaults.removeObject(forKey: Keys.lastCompletionDay)
        }

        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }

    static func debugResetAll() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Keys.startedDay)
        defaults.removeObject(forKey: Keys.completedDay)
        defaults.removeObject(forKey: Keys.lastCompletionDay)
        defaults.removeObject(forKey: Keys.currentStreak)
        defaults.removeObject(forKey: Keys.longestStreak)
        defaults.removeObject(forKey: Keys.longestStreakDate)

        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }
}
