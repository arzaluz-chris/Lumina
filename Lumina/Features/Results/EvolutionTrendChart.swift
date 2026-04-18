import SwiftUI
import Charts

/// Line + point chart showing the points trajectory of a single VIA
/// strength across all completed tests. Rendered inside a `CardContainer`
/// by `EvolutionView`.
struct EvolutionTrendChart: View {
    let strength: Strength
    let series: [(date: Date, points: Int)]

    @State private var highlighted: Date?

    private var latest: (date: Date, points: Int)? { series.last }
    private var peak: (date: Date, points: Int)? {
        series.max(by: { $0.points < $1.points })
    }
    private var valley: (date: Date, points: Int)? {
        series.min(by: { $0.points < $1.points })
    }

    private var color: Color { Theme.categoryColor(for: strength.id) }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            header

            if series.count < 2 {
                Text("Necesitas al menos dos tests para ver la tendencia.")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Theme.spacingL)
            } else {
                chart
            }

            if series.count >= 2 {
                summaryFooter
            }
        }
    }

    private var header: some View {
        HStack(spacing: Theme.spacingM) {
            Image(systemName: strength.iconSF)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Circle().fill(color.gradient))
            VStack(alignment: .leading, spacing: 2) {
                Text(strength.nameES)
                    .font(Theme.subheadFont)
                    .foregroundStyle(Theme.primaryText)
                Text(strength.virtueCategory.nameES)
                    .font(Theme.captionFont)
                    .foregroundStyle(color)
            }
            Spacer(minLength: 0)
            if let latest {
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(latest.points)")
                        .font(Theme.numericFont)
                        .foregroundStyle(Theme.primaryText)
                    Text("actual")
                        .font(.caption2)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(series, id: \.date) { entry in
                AreaMark(
                    x: .value("Fecha", entry.date),
                    y: .value("Puntos", entry.points)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [color.opacity(0.32), color.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Fecha", entry.date),
                    y: .value("Puntos", entry.points)
                )
                .foregroundStyle(color)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                PointMark(
                    x: .value("Fecha", entry.date),
                    y: .value("Puntos", entry.points)
                )
                .foregroundStyle(color)
                .symbolSize(80)
            }

            if let peak {
                PointMark(
                    x: .value("Fecha", peak.date),
                    y: .value("Puntos", peak.points)
                )
                .foregroundStyle(Theme.gold)
                .symbolSize(140)
                .annotation(position: .top) {
                    Text("Máx \(peak.points)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.gold)
                }
            }

            if let highlighted,
               let entry = series.first(where: { Calendar.current.isDate($0.date, inSameDayAs: highlighted) }) {
                RuleMark(x: .value("Fecha", entry.date))
                    .foregroundStyle(color.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
        }
        .chartYScale(domain: 2...10)
        .chartYAxis {
            AxisMarks(values: [2, 5, 8, 10]) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .month, count: max(1, series.count / 4))) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).year(.twoDigits))
            }
        }
        .chartXSelection(value: $highlighted)
        .frame(height: 220)
        .sensoryFeedback(.selection, trigger: highlighted)
    }

    private var summaryFooter: some View {
        HStack(spacing: Theme.spacingL) {
            if let peak {
                summaryMetric(
                    title: "Máximo",
                    value: "\(peak.points)",
                    date: peak.date,
                    tint: Theme.gold
                )
            }
            if let valley {
                summaryMetric(
                    title: "Mínimo",
                    value: "\(valley.points)",
                    date: valley.date,
                    tint: Theme.lavender
                )
            }
            if let latest, let first = series.first {
                let delta = latest.points - first.points
                summaryMetric(
                    title: "Cambio total",
                    value: delta >= 0 ? "+\(delta)" : "\(delta)",
                    date: nil,
                    tint: delta >= 0 ? Theme.success : Theme.danger
                )
            }
        }
    }

    private func summaryMetric(title: LocalizedStringKey, value: String, date: Date?, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.secondaryText)
            Text(value)
                .font(Theme.numericFont)
                .foregroundStyle(tint)
            if let date {
                Text(date.formatted(.dateTime.month(.abbreviated).year(.twoDigits)))
                    .font(.caption2)
                    .foregroundStyle(Theme.secondaryText)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
