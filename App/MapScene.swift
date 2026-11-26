import MapKit
import NearMissCore
import SwiftUI

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

    /// Where each of the two stood. A cell is about 150 m wide, so two people in the
    /// same cell land on the same point; they are drawn a few steps apart instead,
    /// which is as true as the cell allows.
    static func endpoints(of miss: NearMiss) -> (mine: CLLocationCoordinate2D, theirs: CLLocationCoordinate2D)? {
        guard var a = coordinate(of: miss.mine.cell), var b = coordinate(of: miss.theirs.cell) else {
            return nil
        }
        if miss.meters < 30 {
            let metersPerDegree = 111_320 * max(0.2, cos(a.latitude * .pi / 180))
            let shift = 24 / metersPerDegree
            a.longitude -= shift
            b.longitude += shift
        }
        return (a, b)
    }

    /// The camera for one near miss. When they were close it comes down to the street,
    /// tilted, and turned so the two stand side by side. When they were far it frames both.
    static func camera(for miss: NearMiss) -> MapCameraPosition? {
        guard let (a, b) = endpoints(of: miss) else { return nil }
        if miss.meters > 4000 {
            let span = miss.meters * 3.2
            if span > 1_500_000 {
                return .region(region(fitting: [a, b], padding: 1.8))
            }
            return .region(MKCoordinateRegion(center: midpoint(a, b), latitudinalMeters: span, longitudinalMeters: span))
        }
        let close = miss.meters <= 1200
        return .camera(MapCamera(
            centerCoordinate: midpoint(a, b),
            distance: max(miss.meters * 6.2, 620),
            heading: bearing(from: a, to: b) - 90,
            pitch: close ? 48 : 30
        ))
    }

    /// The last steps of each of the two before the near miss, for the walking animation.
    /// A trail only knows the cell and the day, not the route, so these paths are drawn
    /// for the eye: each one comes in from its own side and stops where the photo was taken.
    static func walkPaths(for miss: NearMiss) -> (mine: [CLLocationCoordinate2D], theirs: [CLLocationCoordinate2D])? {
        guard let (a, b) = endpoints(of: miss) else { return nil }
        let middle = midpoint(a, b)
        let perLat = 111_320.0
        let perLon = 111_320.0 * max(0.2, cos(middle.latitude * .pi / 180))
        func local(_ c: CLLocationCoordinate2D) -> (x: Double, y: Double) {
            ((c.longitude - middle.longitude) * perLon, (c.latitude - middle.latitude) * perLat)
        }
        func coordinate(_ x: Double, _ y: Double) -> CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: middle.latitude + y / perLat, longitude: middle.longitude + x / perLon)
        }
        let pa = local(a), pb = local(b)
        let gap = max(1, hypot(pa.x - pb.x, pa.y - pb.y))
        let ux = (pa.x - pb.x) / gap, uy = (pa.y - pb.y) / gap
        let px = -uy, py = ux
        let length = max(90, miss.meters * 0.55)

        func path(to end: (x: Double, y: Double), side: Double) -> [CLLocationCoordinate2D] {
            // Mostly across the line between the two, so the whole walk stays on screen.
            let start = (x: end.x + side * (ux * length * 0.3 + px * length),
                         y: end.y + side * (uy * length * 0.3 + py * length))
            let control = (x: end.x + side * (-ux * length * 0.25 + px * length * 0.5),
                           y: end.y + side * (-uy * length * 0.25 + py * length * 0.5))
            return (0...48).map { step in
                let t = Double(step) / 48, r = 1 - t
                return coordinate(
                    r * r * start.x + 2 * r * t * control.x + t * t * end.x,
                    r * r * start.y + 2 * r * t * control.y + t * t * end.y
                )
            }
        }
        return (path(to: pa, side: 1), path(to: pb, side: -1))
    }

    /// The part of a path already walked at `progress` (0 to 1); its last point is the walker.
    static func walked(_ path: [CLLocationCoordinate2D], progress: Double) -> [CLLocationCoordinate2D] {
        guard path.count > 1 else { return path }
        let position = min(1, max(0, progress)) * Double(path.count - 1)
        let index = Int(position)
        var result = Array(path[0...index])
        if index < path.count - 1 {
            let f = position - Double(index)
            let p = path[index], q = path[index + 1]
            result.append(CLLocationCoordinate2D(
                latitude: p.latitude + (q.latitude - p.latitude) * f,
                longitude: p.longitude + (q.longitude - p.longitude) * f
            ))
        }
        return result
    }

    /// Compass direction from one point to another, in degrees.
    static func bearing(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Double {
        let lat1 = a.latitude * .pi / 180, lat2 = b.latitude * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let degrees = atan2(y, x) * 180 / .pi
        return (degrees + 360).truncatingRemainder(dividingBy: 360)
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
