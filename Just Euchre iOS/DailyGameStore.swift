//
//  DailyGameStore.swift
//  Just Euchre iOS
//
//  One-game-per-day gate + streak tracking.
//  Three game states: win, loss, incomplete.
//  - currentWinStreak: consecutive days with a win (fire icon)
//  - currentCompletedStreak: consecutive days with any completed game (checkmark icon)
//  - longestStreak: longest winning streak ever
//

import Foundation
import WidgetKit

enum DailyGameStore {
    static let didChangeNotification = Notification.Name("justeuchre.daily.didChange")

    /// Shared with the widget extension via the App Group.
    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: "group.Ryland-Dean.Just-Euchre") ?? .standard
    }

    private enum Keys {
        static let startedDay        = "justeuchre.daily.startedDay"       // Date at start-of-day
        static let completedDay      = "justeuchre.daily.completedDay"     // Date at start-of-day
        static let lastCompletionDay = "justeuchre.daily.lastCompletionDay" // Date at start-of-day
        static let currentStreak     = "justeuchre.daily.currentStreak"    // Completed-game streak count
        static let lastWinDay        = "justeuchre.daily.lastWinDay"       // Date at start-of-day
        static let currentWinStreak  = "justeuchre.daily.currentWinStreak"
        static let longestWinStreak      = "justeuchre.daily.longestWinStreak"
        static let longestWinStreakDate  = "justeuchre.daily.longestWinStreakDate"
        static let longestCompletedStreak = "justeuchre.daily.longestCompletedStreak"
    }

    static func todayKeyDate(now: Date = Date()) -> Date {
        Calendar.current.startOfDay(for: now)
    }

    static func hasStartedToday(now: Date = Date()) -> Bool {
        let today = todayKeyDate(now: now)
        guard let started = sharedDefaults.object(forKey: Keys.startedDay) as? Date else { return false }
        return Calendar.current.isDate(started, inSameDayAs: today)
    }

    static func isCompletedToday(now: Date = Date()) -> Bool {
        let today = todayKeyDate(now: now)
        guard let completed = sharedDefaults.object(forKey: Keys.completedDay) as? Date else { return false }
        return Calendar.current.isDate(completed, inSameDayAs: today)
    }

    static func canStartNewGameToday(now: Date = Date()) -> Bool {
        !hasStartedToday(now: now)
    }

    static func markStartedToday(now: Date = Date()) {
        let today = todayKeyDate(now: now)
        sharedDefaults.set(today, forKey: Keys.startedDay)
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }

    /// Call when the daily game ends. `didWin` determines whether the win streak advances.
    /// An incomplete day (started but never completed before next day) does not call this,
    /// which naturally breaks both streaks via the staleness checks in the computed properties.
    static func markCompletedToday(didWin: Bool, now: Date = Date()) {
        let today = todayKeyDate(now: now)
        if isCompletedToday(now: now) { return }

        let defaults = sharedDefaults
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)

        // --- Completed-game streak ---
        let lastCompletion = defaults.object(forKey: Keys.lastCompletionDay) as? Date
        var completedStreak = defaults.integer(forKey: Keys.currentStreak)
        if let lastCompletion, let yesterday,
           Calendar.current.isDate(lastCompletion, inSameDayAs: yesterday) {
            completedStreak += 1
        } else {
            completedStreak = 1
        }

        // --- Win streak ---
        let lastWin = defaults.object(forKey: Keys.lastWinDay) as? Date
        var winStreak = defaults.integer(forKey: Keys.currentWinStreak)
        if didWin {
            if let lastWin, let yesterday,
               Calendar.current.isDate(lastWin, inSameDayAs: yesterday) {
                winStreak += 1
            } else {
                winStreak = 1
            }
            defaults.set(today, forKey: Keys.lastWinDay)
            defaults.set(winStreak, forKey: Keys.currentWinStreak)

            let longest = defaults.integer(forKey: Keys.longestWinStreak)
            if winStreak > longest {
                defaults.set(winStreak, forKey: Keys.longestWinStreak)
                defaults.set(today, forKey: Keys.longestWinStreakDate)
            }
        } else {
            // A loss resets the win streak
            defaults.set(0, forKey: Keys.currentWinStreak)
        }

        defaults.set(today, forKey: Keys.completedDay)
        defaults.set(today, forKey: Keys.lastCompletionDay)
        defaults.set(completedStreak, forKey: Keys.currentStreak)

        let longestCompleted = defaults.integer(forKey: Keys.longestCompletedStreak)
        if completedStreak > longestCompleted {
            defaults.set(completedStreak, forKey: Keys.longestCompletedStreak)
        }

        NotificationCenter.default.post(name: didChangeNotification, object: nil)
        WidgetCenter.shared.reloadTimelines(ofKind: "StreakWidget")
    }

    /// Consecutive winning days. Returns 0 if the last win was more than 1 day ago (streak broken by incomplete or loss).
    static var currentWinStreak: Int {
        let defaults = sharedDefaults
        guard let lastWin = defaults.object(forKey: Keys.lastWinDay) as? Date else { return 0 }
        let today = todayKeyDate()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        guard Calendar.current.isDate(lastWin, inSameDayAs: today) ||
              Calendar.current.isDate(lastWin, inSameDayAs: yesterday) else { return 0 }
        return defaults.integer(forKey: Keys.currentWinStreak)
    }

    /// Consecutive days with any completed game (win or loss). Returns 0 if broken by an incomplete day.
    static var currentCompletedStreak: Int {
        let defaults = sharedDefaults
        guard let lastCompletion = defaults.object(forKey: Keys.lastCompletionDay) as? Date else { return 0 }
        let today = todayKeyDate()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        guard Calendar.current.isDate(lastCompletion, inSameDayAs: today) ||
              Calendar.current.isDate(lastCompletion, inSameDayAs: yesterday) else { return 0 }
        return defaults.integer(forKey: Keys.currentStreak)
    }

    /// Longest winning streak ever recorded.
    static var longestStreak: Int {
        sharedDefaults.integer(forKey: Keys.longestWinStreak)
    }

    /// Longest completed-game streak ever recorded (wins + losses, no incompletes).
    static var longestCompletedStreak: Int {
        sharedDefaults.integer(forKey: Keys.longestCompletedStreak)
    }

    static var longestStreakDate: Date? {
        sharedDefaults.object(forKey: Keys.longestWinStreakDate) as? Date
    }

    // MARK: - Developer utilities

    static func debugResetToday(now: Date = Date()) {
        let today = todayKeyDate(now: now)
        let defaults = sharedDefaults

        if let started = defaults.object(forKey: Keys.startedDay) as? Date,
           Calendar.current.isDate(started, inSameDayAs: today) {
            defaults.removeObject(forKey: Keys.startedDay)
        }
        if let completed = defaults.object(forKey: Keys.completedDay) as? Date,
           Calendar.current.isDate(completed, inSameDayAs: today) {
            defaults.removeObject(forKey: Keys.completedDay)
        }
        if let last = defaults.object(forKey: Keys.lastCompletionDay) as? Date,
           Calendar.current.isDate(last, inSameDayAs: today) {
            defaults.removeObject(forKey: Keys.lastCompletionDay)
        }

        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }

    static func debugResetAll() {
        let defaults = sharedDefaults
        defaults.removeObject(forKey: Keys.startedDay)
        defaults.removeObject(forKey: Keys.completedDay)
        defaults.removeObject(forKey: Keys.lastCompletionDay)
        defaults.removeObject(forKey: Keys.currentStreak)
        defaults.removeObject(forKey: Keys.lastWinDay)
        defaults.removeObject(forKey: Keys.currentWinStreak)
        defaults.removeObject(forKey: Keys.longestWinStreak)
        defaults.removeObject(forKey: Keys.longestWinStreakDate)
        defaults.removeObject(forKey: Keys.longestCompletedStreak)

        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }
}
