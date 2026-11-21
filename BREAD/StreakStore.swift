//
//  StreakStore.swift
//  BREAD
//
//  Daily streak rules shared by the homepage and the finish screen.
//

import Foundation

/// Keeps the streak honest:
/// - it can only go up once per calendar day, and
/// - it drops back to 0 once a whole day passes without finishing a plan.
enum StreakStore {
    /// What happened when a plan was finished.
    struct Completion {
        let days: Int
        let lastIncrease: Double
        /// True when today's streak point was already earned, so the
        /// number did not change.
        let alreadyCountedToday: Bool
    }

    /// Days between the last completion and `now`, measured in calendar
    /// days instead of 24-hour blocks.
    private static func dayGap(
        from lastIncrease: Double,
        to now: Date,
        calendar: Calendar
    ) -> Int {
        let lastDay = calendar.startOfDay(for: Date(timeIntervalSince1970: lastIncrease))
        let today = calendar.startOfDay(for: now)
        return calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
    }

    /// Call when the homepage appears: if a whole day was missed, reset the
    /// streak to 0. Otherwise leave it alone.
    static func daysAfterCheckingForMissedDay(
        currentDays: Int,
        lastIncrease: Double,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        guard lastIncrease > 0 else { return currentDays }
        return dayGap(from: lastIncrease, to: now, calendar: calendar) > 1 ? 0 : currentDays
    }

    /// Call when a plan is finished.
    ///
    /// - First ever finish: +1.
    /// - Already finished today: no change.
    /// - Finished yesterday: +1.
    /// - Missed a whole day or more: reset to 1.
    static func registerCompletion(
        currentDays: Int,
        lastIncrease: Double,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Completion {
        guard lastIncrease > 0 else {
            return Completion(
                days: currentDays + 1,
                lastIncrease: now.timeIntervalSince1970,
                alreadyCountedToday: false
            )
        }

        let gap = dayGap(from: lastIncrease, to: now, calendar: calendar)

        // Today already counted (or the clock moved backwards): leave it be.
        guard gap > 0 else {
            return Completion(
                days: currentDays,
                lastIncrease: lastIncrease,
                alreadyCountedToday: true
            )
        }

        if gap == 1 {
            return Completion(
                days: currentDays + 1,
                lastIncrease: now.timeIntervalSince1970,
                alreadyCountedToday: false
            )
        }

        // A whole day (or more) was missed.
        return Completion(
            days: 1,
            lastIncrease: now.timeIntervalSince1970,
            alreadyCountedToday: false
        )
    }
}
