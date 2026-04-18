import SwiftUI
import Charts

/// Horizontal diverging bar chart showing per-strength point deltas
/// between the current and previous completed tests.
///
/// Green bars for improvements, red for regressions; the magnitude
/// encodes the absolute point change. Rows are sorted by |delta|
/// descending so the most notable movements sit at the top.
struct EvolutionDeltaChart: View {
    let deltas: [StrengthEvolutionStats.Delta]
    /// Max rows to display. Keeps the chart scannable on phone.
    var maxRows: Int = 10

    private var visible: [StrengthEvolutionStats.Delta] {
        Array(deltas.prefix(maxRows)).filter { $0.pointsDelta != 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            headline

            if visible.isEmpty {
                noChanges
            } else {
                Chart(visible) { delta in
                    let strength = StrengthsCatalog.strength(id: delta.strengthID)
                    let name = strength?.nameES ?? delta.strengthID

                    BarMark(
                        x: .value("Δ", delta.pointsDelta),
                        y: .value("Fortaleza", name)
                    )
                    .foregroundStyle(delta.pointsDelta >= 0 ? Theme.success.gradient : Theme.danger.gradient)
                    .cornerRadius(6)
                    .annotation(position: .trailing) {
                        Text(delta.pointsDelta > 0 ? "+\(delta.pointsDelta)" : "\(delta.pointsDelta)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(delta.pointsDelta >= 0 ? Theme.success : Theme.danger)
                            .monospacedDigit()
                    }
                }
                .chartXScale(domain: xDomain)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let intVal = value.as(Int.self) {
                                Text(intVal > 0 ? "+\(intVal)" : "\(intVal)")
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisValueLabel(horizontalSpacing: 6)
                            .font(Theme.captionFont)
                    }
                }
                .frame(height: CGFloat(max(visible.count, 3)) * 34 + 40)
            }
        }
    }

    private var xDomain: ClosedRange<Int> {
        let raw = visible.map(\.pointsDelta)
        let magnitude = max(1, raw.map(abs).max() ?? 1)
        return (-magnitude)...magnitude
    }

    private var headline: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Cambios desde tu test anterior")
                .font(Theme.subheadFont)
                .foregroundStyle(Theme.primaryText)
            Spacer()
            Text("Puntos")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.secondaryText)
        }
    }

    private var noChanges: some View {
        HStack(spacing: Theme.spacingM) {
            Image(systemName: "equal.circle.fill")
                .foregroundStyle(Theme.secondaryText)
            Text("Tus puntajes son iguales a tu test anterior.")
                .font(Theme.captionFont)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Theme.spacingM)
    }
}
