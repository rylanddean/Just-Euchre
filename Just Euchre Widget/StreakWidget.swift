//
//  StreakWidget.swift
//  Just Euchre Widget
//
//  Home screen widget displaying win streak and completed-game streak.
//  Mirrors the streak row from HomeViewController.
//

import WidgetKit
import SwiftUI

// MARK: - Shared storage

/// Must match the App Group entitlement in both targets.
private let kAppGroup = "group.Ryland-Dean.Just-Euchre"

private enum StreakKeys {
    static let lastWinDay        = "justeuchre.daily.lastWinDay"
    static let currentWinStreak  = "justeuchre.daily.currentWinStreak"
    static let lastCompletionDay = "justeuchre.daily.lastCompletionDay"
    static let currentStreak     = "justeuchre.daily.currentStreak"
}

// MARK: - Streak reader
//
// Mirrors the staleness logic in DailyGameStore so the widget shows 0
// once a streak is broken (last activity > 1 day ago).

private enum StreakReader {
    private static var defaults: UserDefaults {
        UserDefaults(suiteName: kAppGroup) ?? .standard
    }

    static var winStreak: Int {
        let d = defaults
        guard let lastWin = d.object(forKey: StreakKeys.lastWinDay) as? Date else { return 0 }
        let today     = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        guard Calendar.current.isDate(lastWin, inSameDayAs: today) ||
              Calendar.current.isDate(lastWin, inSameDayAs: yesterday) else { return 0 }
        return d.integer(forKey: StreakKeys.currentWinStreak)
    }

    static var completedStreak: Int {
        let d = defaults
        guard let last = d.object(forKey: StreakKeys.lastCompletionDay) as? Date else { return 0 }
        let today     = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        guard Calendar.current.isDate(last, inSameDayAs: today) ||
              Calendar.current.isDate(last, inSameDayAs: yesterday) else { return 0 }
        return d.integer(forKey: StreakKeys.currentStreak)
    }

    /// True once the user has completed at least one game ever.
    static var hasPlayedBefore: Bool {
        defaults.object(forKey: StreakKeys.lastCompletionDay) != nil
    }
}

// MARK: - Timeline

struct StreakEntry: TimelineEntry {
    let date: Date
    let winStreak: Int
    let completedStreak: Int
    let hasPlayedBefore: Bool

    static let placeholder = StreakEntry(date: Date(), winStreak: 3, completedStreak: 5, hasPlayedBefore: true)
}

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(context.isPreview ? .placeholder : makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let entry = makeEntry()
        // Refresh at the next midnight so the widget reflects a new day
        let midnight = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 1),
            matchingPolicy: .nextTime
        ) ?? Date(timeIntervalSinceNow: 86_400)
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }

    private func makeEntry() -> StreakEntry {
        StreakEntry(
            date: Date(),
            winStreak: StreakReader.winStreak,
            completedStreak: StreakReader.completedStreak,
            hasPlayedBefore: StreakReader.hasPlayedBefore
        )
    }
}

// MARK: - Colors

private extension Color {
    static let widgetBg    = Color(red: 8/255,  green: 11/255, blue: 18/255)
    static let flameOrange = Color(red: 1.0,    green: 0.45,   blue: 0.15)
    static let muted       = Color(white: 0.72)
    static let subtle      = Color(white: 0.55)
}

// MARK: - Small widget (2×2)
//
// "Just Euchre" label at top, then flame+count and checkmark+count stacked.

private struct SmallStreakView: View {
    let entry: StreakEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Just Euchre")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.muted)

            Spacer()

            if entry.hasPlayedBefore {
                // Both rows grouped so they stay together and center as a unit
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(Color.flameOrange)
                        Spacer()
                        Text("\(entry.winStreak)")
                            .font(.system(size: 44, weight: .regular))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.5)
                    }

                    HStack(alignment: .center) {
                        Image(systemName: "checkmark.square.fill")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(entry.completedStreak)")
                            .font(.system(size: 44, weight: .regular))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.5)
                    }
                }
            } else {
                Text("Complete your first game to see your streaks.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(16)
        .containerBackground(Color.widgetBg, for: .widget)
    }
}

// MARK: - Widget entry view

struct StreakWidgetEntryView: View {
    let entry: StreakEntry

    var body: some View {
        SmallStreakView(entry: entry)
    }
}

// MARK: - Widget definition

struct StreakWidget: Widget {
    let kind = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Streaks")
        .description("Your win and completed-game streaks.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Entry point

@main
struct JustEuchreWidgetBundle: WidgetBundle {
    var body: some Widget {
        StreakWidget()
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    StreakWidget()
} timeline: {
    StreakEntry.placeholder
}
