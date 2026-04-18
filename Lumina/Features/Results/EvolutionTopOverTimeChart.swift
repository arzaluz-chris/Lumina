import SwiftUI
import Charts

/// Shows how each strength in the user's most-recent top-N has moved
/// through its rank (1 = strongest) across all tests. One line per
/// strength, colored by virtue category; lower on the Y-axis is better.
struct EvolutionTopOverTimeChart: View {
    let stats: StrengthEvolutionStats
    var topN: Int = 5

    /// The strengths currently in the user's top-N, in rank order.
    private var highlightedIDs: [String] {
        guard let latest = stats.samples.last else { return [] }
        let ranked = latest.pointsByStrengthID
            .sorted { lhs, rhs in
                if lhs.value != rhs.value { return lhs.value > rhs.value }
                return lhs.key < rhs.key
            }
            .prefix(topN)
            .map { $0.key }
        return Array(ranked)
    }

    private struct Point: Identifiable {
        let id = UUID()
        let strengthID: String
        let name: String
        let date: Date
        let rank: Int
    }

    private var allPoints: [Point] {
        highlightedIDs.flatMap { id -> [Point] in
            let name = StrengthsCatalog.strength(id: id)?.nameES ?? id
            return stats.rankHistory(for: id).map { entry in
                Point(strengthID: id, name: name, date: entry.date, rank: entry.rank)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            header

            if stats.samples.count < 2 {
                Text("Vuelve a hacer el test para ver cómo se mueve tu top \(topN).")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Theme.spacingL)
            } else {
                chart
                legend
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Tu top \(topN) a lo largo del tiempo")
                .font(Theme.subheadFont)
                .foregroundStyle(Theme.primaryText)
            Text("Cuanto más arriba, mejor posición: #1 es la fortaleza más expresada en cada test.")
                .font(Theme.captionFont)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var chart: some View {
        Chart(allPoints) { point in
            LineMark(
                x: .value("Fecha", point.date),
                y: .value("Posición", point.rank),
                series: .value("Fortaleza", point.name)
            )
            .foregroundStyle(Theme.categoryColor(for: point.strengthID))
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

            PointMark(
                x: .value("Fecha", point.date),
                y: .value("Posición", point.rank)
            )
            .foregroundStyle(Theme.categoryColor(for: point.strengthID))
            .symbolSize(60)
        }
        .chartYScale(domain: .automatic(includesZero: false, reversed: true))
        .chartYAxis {
            AxisMarks(values: [1, 5, 10, 15, 20, 24]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let intVal = value.as(Int.self) {
                        Text("#\(intVal)")
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .month, count: max(1, stats.samples.count / 4))) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).year(.twoDigits))
            }
        }
        .frame(height: 240)
    }

    private var legend: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: Theme.spacingS)], spacing: Theme.spacingS) {
            ForEach(highlightedIDs, id: \.self) { id in
                HStack(spacing: Theme.spacingS) {
                    Circle()
                        .fill(Theme.categoryColor(for: id))
                        .frame(width: 10, height: 10)
                    Text(StrengthsCatalog.strength(id: id)?.nameES ?? id)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
            }
        }
    }
}
