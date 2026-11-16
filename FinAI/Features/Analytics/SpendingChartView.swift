//
//  SpendingChartView.swift
//  FinAI
//
//  Created by Tommy on 16.10.26.
//

import Charts
import SwiftUI

struct SpendingChartView: View {
    let days: [DailySpending]
    let currency: Currency
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            DisclosureGroup(.dailyTotals) {
                ForEach(days) { day in
                    VStack(alignment: .leading, spacing: FinanceStyle.Spacing.compact) {
                        Text(day.date, format: .dateTime.day().month().year())
                        MoneyText(money: day.netSpending)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        } else {
            chart
        }
    }

    private var chart: some View {
        Chart(days) { day in
            // Floating point is used only for chart coordinates, never financial arithmetic.
            BarMark(
                x: .value(String(localized: .date), day.date, unit: .day, calendar: calendar),
                y: .value(String(localized: .netSpending), NSDecimalNumber(decimal: day.netSpending.amount).doubleValue)
            )
            .foregroundStyle(FinanceStyle.ColorRole.accent)
            .accessibilityLabel(Text(day.date, format: .dateTime.day().month().year()))
            .accessibilityValue(Text(day.netSpending.amount, format: .currency(code: currency.code).locale(locale)))
        }
        .chartXAxis { AxisMarks(values: .stride(by: .day, count: 10)) { AxisValueLabel(format: .dateTime.day().month(.abbreviated)) } }
        .chartYAxis { AxisMarks(position: .leading) }
        .chartYAxisLabel { Text(verbatim: currency.code) }
        .frame(height: 200)
        .accessibilityLabel(.dailyNetSpending)
    }
}
