//
//  NotificationStore.swift
//  Just Euchre iOS
//

import Foundation

enum NotificationStore {
    private static let hourKey    = "justeuchre.notification.hour"
    private static let minuteKey  = "justeuchre.notification.minute"
    private static let enabledKey = "justeuchre.notification.enabled"
    private static let offsetKey  = "justeuchre.notification.msgOffset"

    static var hour: Int {
        get {
            guard let v = UserDefaults.standard.object(forKey: hourKey) as? Int else { return 8 }
            return v
        }
        set { UserDefaults.standard.set(newValue, forKey: hourKey) }
    }

    static var minute: Int {
        get {
            guard let v = UserDefaults.standard.object(forKey: minuteKey) as? Int else { return 0 }
            return v
        }
        set { UserDefaults.standard.set(newValue, forKey: minuteKey) }
    }

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    /// A random per-install offset so the message order feels unique per device.
    static var messageOffset: Int {
        get {
            if let v = UserDefaults.standard.object(forKey: offsetKey) as? Int { return v }
            let fresh = Int.random(in: 0..<DailyNotificationMessages.all.count)
            UserDefaults.standard.set(fresh, forKey: offsetKey)
            return fresh
        }
    }

    static var timeDisplayString: String {
        var c = DateComponents()
        c.hour = hour
        c.minute = minute
        guard let date = Calendar.current.date(from: c) else { return "8:00 AM" }
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        fmt.dateStyle = .none
        return fmt.string(from: date)
    }
}
