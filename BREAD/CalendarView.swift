//
//  CalendarView.swift
//  BREAD
//
//  Created by T Krobot on 11/25/26.
//

import SwiftUI

struct CalendarView: View {
    @State private var selectedDate = Date()
    @Namespace private var animation

    var body: some View {
        VStack(spacing: 0) {
            // Calendar header with navigation
            HStack {
                Button {
                    withAnimation(.easeInOut) {
                        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? Date()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(BreadTheme.secondaryText)
                        .frame(width: 30, height: 30)
                }

                Spacer()

                Text(selectedDate.format("MMMM yyyy"))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(BreadTheme.text)
                    .frame(maxWidth: .infinity)

                Spacer()

                Button {
                    withAnimation(.easeInOut) {
                        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? Date()
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(BreadTheme.secondaryText)
                        .frame(width: 30, height: 30)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            // Day grid header
            HStack {
                ForEach(Calendar.current.shortWeekdaySymbols.prefix(7), id: \.self) { day in
                    Text(day)
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundStyle(BreadTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)

            // Days grid
            let calendar = Calendar.current
            let dateInterval = calendar.dateInterval(of: .day, for: selectedDate)!
            let daysInMonth = calendar.dateComponents([.day], from: dateInterval.start, to: dateInterval.end.addingTimeInterval(86400)).day ?? 0
            let firstWeekday = calendar.component(.weekday, from: dateInterval.start) % 7
            // previous month days to fill the grid (offset from start of first week)
            let previousMonthDays = calendar.component(.day, from: dateInterval.start.addingTimeInterval(-86400))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                // Previous month days
                ForEach(0..<firstWeekday) { i in
                    let dayNumber = previousMonthDays - i + 1
                    Text("\(dayNumber)")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(BreadTheme.muted)
                        .frame(width: 32, height: 32)
                        .background(Color.clear)
                }

                // Current month days
                ForEach(0..<daysInMonth, id: \.self) { dayIdx in
                    let day = dayIdx + 1
                    let date = calendar.date(byAdding: .day, value: dayIdx, to: dateInterval.start)!
                    let isToday = calendar.isDate(date, inSameDayAs: Date())
                    let hasPlan = finishedPlans(for: date).isNotEmpty

                    Button {
                        withAnimation(.easeInOut) {
                            selectedDate = date
                        }
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Text("\(day)")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(isToday && !hasPlan ? BreadTheme.text : (hasPlan ? BreadTheme.accent : BreadTheme.secondaryText))
                                .frame(width: isToday ? 40 : 32, height: isToday ? 40 : 32)
                                .background(
                                    Circle()
                                        .fill(isToday ? BreadTheme.accent.opacity(0.2) : Color.clear)
                                        .frame(width: isToday ? 40 : 32, height: isToday ? 40 : 32)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(BreadTheme.accent, lineWidth: hasPlan ? 2 : 0)
                                        .frame(width: isToday ? 40 : 32, height: isToday ? 40 : 32)
                                )

                            if hasPlan {
                                Circle()
                                    .fill(BreadTheme.accent)
                                    .frame(width: 8, height: 8)
                                    .offset(x: isToday ? 10 : 12, y: isToday ? 10 : 12)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Spacer days at end of month (to fill grid)
                let totalCells = firstWeekday + daysInMonth
                let extra = (totalCells % 7 != 0 ? 7 - (totalCells % 7) : 0)
                ForEach(0..<extra) { _ in
                    Rectangle()
                        .frame(width: 32, height: 32)
                        .foregroundStyle(Color.clear)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)

            Spacer()

            // Navigate back to home
            Button {
                // dismiss or navigate
            } label: {
                Text("Done")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(BreadTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(BreadTheme.surface)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
        }
        .background(BreadTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Return true if there is at least one finished plan on this date.
    private func finishedPlans(for date: Date) -> [FinishedPlan] {
        // Load saved finished plans from UserDefaults
        guard let data = UserDefaults.standard.data(forKey: "finishedPlans"),
              let plans = try? JSONDecoder().decode([FinishedPlan].self, from: data) else {
            return []
        }
        return plans.filter { plan in
            calendar.isDate(plan.date, inSameDayAs: date)
        }
    }

    private var calendar: Calendar {
        Calendar.current
    }
}

private extension Date {
    func format(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.timeZone = TimeZone.current
        return formatter.string(from: self)
    }
}

private extension Array where Element == FinishedPlan {
    var isNotEmpty: Bool { !isEmpty }
}