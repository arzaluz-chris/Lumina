import Foundation

/// Pure-Swift, SwiftData-free statistical helpers for the Evolution
/// visualization. Takes a plain array of per-test snapshots so the same
/// math can be exercised from SwiftUI views, Previews, and unit tests
/// without needing a live `ModelContext`.
struct StrengthEvolutionStats: Sendable {
    /// One test result's worth of data in a form the stats layer can
    /// use without touching SwiftData.
    struct Sample: Sendable {
        let date: Date
        /// Keys are `Strength.id`, values are raw points (2…10).
        let pointsByStrengthID: [String: Int]
    }

    /// Samples sorted ascending by `date` (oldest first). The charts
    /// expect chronological order.
    let samples: [Sample]

    init(samples: [Sample]) {
        self.samples = samples.sorted { $0.date < $1.date }
    }

    // MARK: - Trend per strength

    /// The raw score trajectory for a single strength across all tests.
    /// Missing tests (a strength that wasn't scored for some reason) are
    /// skipped, not zero-padded.
    func trendSeries(for strengthID: String) -> [(date: Date, points: Int)] {
        samples.compactMap { sample in
            guard let points = sample.pointsByStrengthID[strengthID] else { return nil }
            return (sample.date, points)
        }
    }

    // MARK: - Rank history

    /// The ordinal rank (1 = strongest, 24 = weakest) of a single
    /// strength over time. Ties are broken by the strength ID's
    /// lexical order so the chart stays deterministic between
    /// identical-tied renders.
    func rankHistory(for strengthID: String) -> [(date: Date, rank: Int)] {
        samples.compactMap { sample in
            let ranked = sample.pointsByStrengthID
                .sorted { lhs, rhs in
                    if lhs.value != rhs.value { return lhs.value > rhs.value }
                    return lhs.key < rhs.key
                }
            guard let index = ranked.firstIndex(where: { $0.key == strengthID }) else { return nil }
            return (sample.date, index + 1)
        }
    }

    // MARK: - Delta between two tests

    struct Delta: Sendable, Identifiable {
        var id: String { strengthID }
        let strengthID: String
        let previousPoints: Int
        let currentPoints: Int
        let previousRank: Int
        let currentRank: Int

        var pointsDelta: Int { currentPoints - previousPoints }
        /// Rank going down (from #5 to #2) is a positive improvement,
        /// so the rank delta is inverted from the raw numbers.
        var rankDelta: Int { previousRank - currentRank }
    }

    /// Per-strength deltas between `previous` and `current` tests,
    /// sorted by absolute points delta, descending. Strengths that
    /// appear in only one of the two tests are skipped.
    static func deltas(previous: Sample, current: Sample) -> [Delta] {
        let previousRanked = previous.pointsByStrengthID
            .sorted { lhs, rhs in
                if lhs.value != rhs.value { return lhs.value > rhs.value }
                return lhs.key < rhs.key
            }
        let currentRanked = current.pointsByStrengthID
            .sorted { lhs, rhs in
                if lhs.value != rhs.value { return lhs.value > rhs.value }
                return lhs.key < rhs.key
            }
        let previousRank = Dictionary(uniqueKeysWithValues: previousRanked.enumerated().map { ($0.element.key, $0.offset + 1) })
        let currentRank = Dictionary(uniqueKeysWithValues: currentRanked.enumerated().map { ($0.element.key, $0.offset + 1) })

        var deltas: [Delta] = []
        for (strengthID, currentPoints) in current.pointsByStrengthID {
            guard let previousPoints = previous.pointsByStrengthID[strengthID] else { continue }
            deltas.append(Delta(
                strengthID: strengthID,
                previousPoints: previousPoints,
                currentPoints: currentPoints,
                previousRank: previousRank[strengthID] ?? 24,
                currentRank: currentRank[strengthID] ?? 24
            ))
        }
        return deltas.sorted { abs($0.pointsDelta) > abs($1.pointsDelta) }
    }

    // MARK: - Top-N over time

    /// For each test, returns the IDs of the N highest-scoring strengths
    /// in rank order. Ties broken lexically by strength ID.
    func topNOverTime(_ n: Int = 5) -> [(date: Date, topIDs: [String])] {
        samples.map { sample in
            let top = sample.pointsByStrengthID
                .sorted { lhs, rhs in
                    if lhs.value != rhs.value { return lhs.value > rhs.value }
                    return lhs.key < rhs.key
                }
                .prefix(n)
                .map { $0.key }
            return (sample.date, Array(top))
        }
    }

    /// Count how many of the user's current top-N have been in the
    /// top-N across all past tests. Useful as a "stability" summary:
    /// higher = your signature strengths have been consistent.
    func signatureConsistency(topN n: Int = 5) -> Double {
        guard let latest = samples.last else { return 1.0 }
        let latestTop = Set(
            latest.pointsByStrengthID
                .sorted { lhs, rhs in
                    if lhs.value != rhs.value { return lhs.value > rhs.value }
                    return lhs.key < rhs.key
                }
                .prefix(n)
                .map { $0.key }
        )
        let appearances = samples.dropLast().reduce(0) { acc, sample in
            let top = Set(
                sample.pointsByStrengthID
                    .sorted { lhs, rhs in
                        if lhs.value != rhs.value { return lhs.value > rhs.value }
                        return lhs.key < rhs.key
                    }
                    .prefix(n)
                    .map { $0.key }
            )
            return acc + latestTop.intersection(top).count
        }
        let maxAppearances = (samples.count - 1) * latestTop.count
        guard maxAppearances > 0 else { return 1.0 }
        return Double(appearances) / Double(maxAppearances)
    }
}

// MARK: - SwiftData bridge

extension StrengthEvolutionStats {
    /// Convenience initializer that converts a SwiftData `TestResult`
    /// array into the pure-Swift representation.
    init(from results: [TestResult]) {
        self.init(samples: results.map { result in
            var dict: [String: Int] = [:]
            for score in result.scores {
                dict[score.strengthID] = score.points
            }
            return Sample(date: result.completedAt, pointsByStrengthID: dict)
        })
    }
}
