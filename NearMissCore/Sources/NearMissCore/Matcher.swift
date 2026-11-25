import Foundation

/// How close counts as "almost met".
public struct Tolerance: Sendable, Equatable {
    public var meters: Double
    public var days: Int

    public init(meters: Double = 500, days: Int = 0) {
        self.meters = meters
        self.days = days
    }
}

/// One time the two trails came near each other.
public struct NearMiss: Sendable, Equatable, Identifiable {
    public let mine: Sighting
    public let theirs: Sighting
    /// Distance between the centers of the two cells.
    public let meters: Double
    public let dayGap: Int

    public var id: String { "\(mine.cell)-\(mine.day)-\(theirs.cell)-\(theirs.day)" }

    /// One number for "how close": a day apart weighs the same as
    /// `Matcher.metersPerDay` meters apart. Lower is closer.
    public var score: Double { meters / Matcher.metersPerDay + Double(dayGap) }
}

public struct Comparison: Sendable, Equatable {
    /// Near misses within the tolerance, oldest first. At most one per day of each person.
    public let matches: [NearMiss]
    /// The closest the two ever were. Nil only when one trail has no sightings.
    public let closest: NearMiss?

    public init(matches: [NearMiss], closest: NearMiss?) {
        self.matches = matches
        self.closest = closest
    }
}

public enum Matcher {
    public static let metersPerDay = 1000.0
    static let earthRadius = 6_371_000.0

    /// - Parameter beforeDay: when set, only sightings before that day count
    ///   (the day the two met, so that life together is not a "near miss").
    public static func compare(
        mine: [Sighting],
        theirs: [Sighting],
        tolerance: Tolerance,
        beforeDay: Int? = nil
    ) -> Comparison {
        let a = points(from: mine, beforeDay: beforeDay)
        let b = points(from: theirs, beforeDay: beforeDay)
        guard !a.isEmpty, !b.isEmpty else {
            return Comparison(matches: [], closest: nil)
        }

        let matches = matches(a, b, tolerance: tolerance)
        if let best = matches.min(by: isCloser) {
            return Comparison(matches: matches, closest: best)
        }
        return Comparison(matches: [], closest: closest(a, b))
    }

    // MARK: - Internals

    struct Point {
        let sighting: Sighting
        let latitude: Double  // radians
        let longitude: Double  // radians
        let cosLatitude: Double
    }

    static func points(from sightings: [Sighting], beforeDay: Int?) -> [Point] {
        var centers: [String: Coordinate?] = [:]
        var result: [Point] = []
        result.reserveCapacity(sightings.count)
        for sighting in sightings {
            if let beforeDay, sighting.day >= beforeDay { continue }
            let center: Coordinate?
            if let cached = centers[sighting.cell] {
                center = cached
            } else {
                center = Geohash.center(of: sighting.cell)
                centers[sighting.cell] = center
            }
            guard let center else { continue }
            let latitude = center.latitude * .pi / 180
            result.append(
                Point(
                    sighting: sighting,
                    latitude: latitude,
                    longitude: center.longitude * .pi / 180,
                    cosLatitude: cos(latitude)
                )
            )
        }
        return result
    }

    static func distance(_ p: Point, _ q: Point) -> Double {
        let dLat = sin((q.latitude - p.latitude) / 2)
        let dLon = sin((q.longitude - p.longitude) / 2)
        let h = dLat * dLat + p.cosLatitude * q.cosLatitude * dLon * dLon
        return 2 * earthRadius * asin(min(1, h.squareRoot()))
    }

    static func nearMiss(_ p: Point, _ q: Point, meters: Double) -> NearMiss {
        NearMiss(
            mine: p.sighting,
            theirs: q.sighting,
            meters: meters,
            dayGap: abs(p.sighting.day - q.sighting.day)
        )
    }

    static func isCloser(_ x: NearMiss, _ y: NearMiss) -> Bool {
        if x.score != y.score { return x.score < y.score }
        if x.mine.day != y.mine.day { return x.mine.day < y.mine.day }
        return x.id < y.id
    }

    static func matches(_ a: [Point], _ b: [Point], tolerance: Tolerance) -> [NearMiss] {
        let byDay = Dictionary(grouping: b, by: \.sighting.day)
        let window = max(0, tolerance.days)

        var candidates: [NearMiss] = []
        for p in a {
            for day in (p.sighting.day - window)...(p.sighting.day + window) {
                for q in byDay[day] ?? [] {
                    let meters = distance(p, q)
                    if meters <= tolerance.meters {
                        candidates.append(nearMiss(p, q, meters: meters))
                    }
                }
            }
        }

        // Two people in the same neighborhood for a day produce many cell pairs.
        // Keep the closest pair and use each person's day only once.
        candidates.sort(by: isCloser)
        var usedMine = Set<Int>()
        var usedTheirs = Set<Int>()
        var result: [NearMiss] = []
        for candidate in candidates {
            guard !usedMine.contains(candidate.mine.day),
                  !usedTheirs.contains(candidate.theirs.day)
            else { continue }
            usedMine.insert(candidate.mine.day)
            usedTheirs.insert(candidate.theirs.day)
            result.append(candidate)
        }
        return result.sorted { ($0.mine.day, $0.id) < ($1.mine.day, $1.id) }
    }

    /// The pair with the lowest score over all pairs. Walks outward in time from
    /// each of my sightings and stops once the day gap alone is worse than the best.
    static func closest(_ a: [Point], _ b: [Point]) -> NearMiss? {
        let sorted = b.sorted { $0.sighting.day < $1.sighting.day }
        var best: NearMiss?

        for p in a {
            var hi = lowerBound(sorted, day: p.sighting.day)
            var lo = hi - 1
            while lo >= 0 || hi < sorted.count {
                let gapLo = lo >= 0 ? p.sighting.day - sorted[lo].sighting.day : Int.max
                let gapHi = hi < sorted.count ? sorted[hi].sighting.day - p.sighting.day : Int.max
                let q: Point
                let gap: Int
                if gapLo <= gapHi {
                    q = sorted[lo]
                    gap = gapLo
                    lo -= 1
                } else {
                    q = sorted[hi]
                    gap = gapHi
                    hi += 1
                }
                if let best, Double(gap) > best.score { break }

                // North-south distance alone is a cheap lower bound.
                if let best {
                    let floor = abs(q.latitude - p.latitude) * earthRadius / metersPerDay
                    if floor + Double(gap) > best.score { continue }
                }
                let candidate = nearMiss(p, q, meters: distance(p, q))
                if best.map({ isCloser(candidate, $0) }) ?? true {
                    best = candidate
                }
            }
        }
        return best
    }

    static func lowerBound(_ sorted: [Point], day: Int) -> Int {
        var low = 0
        var high = sorted.count
        while low < high {
            let mid = (low + high) / 2
            if sorted[mid].sighting.day < day { low = mid + 1 } else { high = mid }
        }
        return low
    }
}
