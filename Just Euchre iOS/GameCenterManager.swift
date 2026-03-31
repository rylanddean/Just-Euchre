//
//  GameCenterManager.swift
//  Just Euchre iOS
//
//  Manages Game Center authentication and streak-based achievement reporting.
//  Achievements are personal milestones, not competitive metrics — no leaderboards.
//

import GameKit

final class GameCenterManager: NSObject {

    static let shared = GameCenterManager()
    static let authDidChangeNotification = Notification.Name("justeuchre.gamecenter.authDidChange")

    private(set) var isAuthenticated = false

    private override init() {}

    // MARK: - Authentication

    func authenticate(from viewController: UIViewController?) {
        GKLocalPlayer.local.authenticateHandler = { [weak self, weak viewController] authVC, error in
            guard let self else { return }

            if let authVC, let presenter = viewController {
                presenter.present(authVC, animated: true)
                return
            }

            let authenticated = GKLocalPlayer.local.isAuthenticated
            guard authenticated != self.isAuthenticated else { return }
            self.isAuthenticated = authenticated
            NotificationCenter.default.post(name: GameCenterManager.authDidChangeNotification, object: nil)
        }
    }

    // MARK: - Achievements

    /// Call after every game completion with the freshly updated streak values.
    func reportAchievements(completedStreak: Int, winStreak: Int) {
        guard isAuthenticated else { return }

        var toReport: [GKAchievement] = []

        for threshold in Achievement.completedStreakThresholds where completedStreak >= threshold {
            let id = Achievement.completedStreakID(for: threshold)
            let achievement = GKAchievement(identifier: id)
            achievement.percentComplete = 100
            achievement.showsCompletionBanner = true
            toReport.append(achievement)
        }

        for threshold in Achievement.winStreakThresholds where winStreak >= threshold {
            let id = Achievement.winStreakID(for: threshold)
            let achievement = GKAchievement(identifier: id)
            achievement.percentComplete = 100
            achievement.showsCompletionBanner = true
            toReport.append(achievement)
        }

        guard !toReport.isEmpty else { return }

        GKAchievement.report(toReport) { error in
            if let error {
                print("[GameCenter] Achievement report failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Achievement IDs

    private enum Achievement {
        /// Completed-game streak thresholds (play every day, win or loss).
        static let completedStreakThresholds = [1, 7, 14, 30, 60, 100]

        /// Win streak thresholds (consecutive wins).
        static let winStreakThresholds = [3, 5, 10, 20]

        static func completedStreakID(for threshold: Int) -> String {
            "\(threshold)DayCompletedGameStreak"
        }

        static func winStreakID(for threshold: Int) -> String {
            "streak_win_\(threshold)"
        }
    }
}
