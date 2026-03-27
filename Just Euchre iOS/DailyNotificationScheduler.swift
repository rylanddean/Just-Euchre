//
//  DailyNotificationScheduler.swift
//  Just Euchre iOS
//
//  Schedules up to 64 daily local notifications (iOS limit), each with a
//  unique witty message. On every app launch we top up the queue so there
//  is always a notification ready for the next ~2 months.
//

import UIKit
import UserNotifications

enum DailyNotificationScheduler {

    private static let idPrefix = "justeuchre.daily."

    // MARK: - Public API

    /// Call from settings when the user flips the toggle ON.
    /// Requests permission if needed, then schedules notifications.
    /// The completion closure is called on the main thread with the final enabled state.
    static func enableNotifications(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                        DispatchQueue.main.async {
                            NotificationStore.isEnabled = granted
                            if granted { scheduleUpcoming() }
                            completion(granted)
                        }
                    }
                case .authorized, .provisional, .ephemeral:
                    NotificationStore.isEnabled = true
                    scheduleUpcoming()
                    completion(true)
                case .denied:
                    NotificationStore.isEnabled = false
                    completion(false)
                @unknown default:
                    completion(false)
                }
            }
        }
    }

    /// Call when the user disables notifications in settings.
    static func disableNotifications() {
        NotificationStore.isEnabled = false
        cancelAll()
    }

    /// Call when the user changes the notification time.
    /// Cancels all pending notifications and reschedules at the new time.
    static func reschedule() {
        guard NotificationStore.isEnabled else { return }
        cancelAll {
            scheduleUpcoming()
        }
    }

    /// Call on every app launch to keep the queue topped up.
    static func topUpIfNeeded() {
        guard NotificationStore.isEnabled else { return }
        // Verify the OS permission is still granted before scheduling.
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized ||
                  settings.authorizationStatus == .provisional else {
                DispatchQueue.main.async { NotificationStore.isEnabled = false }
                return
            }
            scheduleUpcoming()
        }
    }

    // MARK: - Scheduling

    private static func scheduleUpcoming() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { pending in
            let ours = pending.filter { $0.identifier.hasPrefix(idPrefix) }

            // Collect day-ordinals already covered so we don't double-schedule.
            let coveredDays: Set<Int> = Set(ours.compactMap { req -> Int? in
                guard let trigger = req.trigger as? UNCalendarNotificationTrigger,
                      let date = trigger.nextTriggerDate() else { return nil }
                return Calendar.current.ordinality(of: .day, in: .era, for: date)
            })

            let needed = 64 - ours.count
            guard needed > 0 else { return }

            let messages = DailyNotificationMessages.all
            let offset = NotificationStore.messageOffset
            let today = Date()
            var scheduled = 0
            var dayOffset = 1

            while scheduled < needed && dayOffset <= 200 {
                defer { dayOffset += 1 }

                guard let futureDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: today),
                      let dayOrdinal = Calendar.current.ordinality(of: .day, in: .era, for: futureDate),
                      !coveredDays.contains(dayOrdinal)
                else { continue }

                var components = Calendar.current.dateComponents([.year, .month, .day], from: futureDate)
                components.hour   = NotificationStore.hour
                components.minute = NotificationStore.minute
                components.second = 0

                let msgIndex = (dayOrdinal + offset) % messages.count
                let msg = messages[msgIndex]

                let content = UNMutableNotificationContent()
                content.title = msg.title
                content.body  = msg.body
                content.sound = .default

                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "\(idPrefix)\(dayOrdinal)",
                    content: content,
                    trigger: trigger
                )
                center.add(request)
                scheduled += 1
            }
        }
    }

    // MARK: - Cancellation

    private static func cancelAll(completion: (() -> Void)? = nil) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { pending in
            let ids = pending.filter { $0.identifier.hasPrefix(idPrefix) }.map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: ids)
            completion?()
        }
    }
}
