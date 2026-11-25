import MapKit
import NearMissCore

/// One sighting placed on the map.
struct TrailPoint: Identifiable {
    let id: Int
    let day: Int
    let coordinate: CLLocationCoordinate2D
}

/// The two trails, ready to draw: sorted by day, with a camera frame that fits both.
struct MapScene {
    let mine: [TrailPoint]
    let theirs: [TrailPoint]
    /// A thinned set of points to draw as dots, so a big library stays light.
    let mineDots: [TrailPoint]
    let theirsDots: [TrailPoint]
    /// Every day on which something appears, in order. The replay steps through it.
    let days: [Int]
    let region: MKCoordinateRegion

    static let maxDots = 140

    init(mine: Trail, theirs: Trail, beforeDay: Int?) {
        self.mine = Self.points(mine, beforeDay: beforeDay)
        self.theirs = Self.points(theirs, beforeDay: beforeDay)
        mineDots = Self.thin(self.mine)
        theirsDots = Self.thin(self.theirs)
        days = Array(Set(self.mine.map(\.day) + self.theirs.map(\.day))).sorted()
        region = Self.region(fitting: (self.mine + self.theirs).map(\.coordinate))
    }

    static func coordinate(of cell: String) -> CLLocationCoordinate2D? {
        Geohash.center(of: cell).map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
    }

    static func midpoint(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: (a.latitude + b.latitude) / 2,
            longitude: (a.longitude + b.longitude) / 2
        )
    }

    /// The smallest frame that shows every coordinate, with air around it.
    static func region(fitting coordinates: [CLLocationCoordinate2D], padding: Double = 1.5) -> MKCoordinateRegion {
        guard let first = coordinates.first else {
            return MKCoordinateRegion(.world)
        }
        var minLat = first.latitude, maxLat = first.latitude
        var minLon = first.longitude, maxLon = first.longitude
        for c in coordinates.dropFirst() {
            minLat = min(minLat, c.latitude)
            maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude)
            maxLon = max(maxLon, c.longitude)
        }
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2),
            span: MKCoordinateSpan(
                latitudeDelta: min(150, max(0.02, (maxLat - minLat) * padding)),
                longitudeDelta: min(340, max(0.02, (maxLon - minLon) * padding))
            )
        )
    }

    /// The frame for one near miss: tight when they were close, wide when they were not.
    static func region(for miss: NearMiss) -> MKCoordinateRegion? {
        guard let a = coordinate(of: miss.mine.cell), let b = coordinate(of: miss.theirs.cell) else {
            return nil
        }
        let span = max(miss.meters * 3.2, 1400)
        if span > 1_500_000 {
            return region(fitting: [a, b], padding: 1.8)
        }
        return MKCoordinateRegion(center: midpoint(a, b), latitudinalMeters: span, longitudinalMeters: span)
    }

    private static func points(_ trail: Trail, beforeDay: Int?) -> [TrailPoint] {
        var result: [TrailPoint] = []
        for sighting in trail.sightings.sorted(by: { ($0.day, $0.cell) < ($1.day, $1.cell) }) {
            if let beforeDay, sighting.day >= beforeDay { continue }
            guard let coordinate = coordinate(of: sighting.cell) else { continue }
            result.append(TrailPoint(id: result.count, day: sighting.day, coordinate: coordinate))
        }
        return result
    }

    private static func thin(_ points: [TrailPoint]) -> [TrailPoint] {
        guard points.count > maxDots else { return points }
        let step = Double(points.count) / Double(maxDots)
        return (0..<maxDots).map { points[Int(Double($0) * step)] }
    }
}
