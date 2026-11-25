import Foundation

/// What the app reads from one photo: where and when. Never leaves the device.
public struct PhotoPoint: Sendable, Equatable {
    public let latitude: Double
    public let longitude: Double
    public let date: Date

    public init(latitude: Double, longitude: Double, date: Date) {
        self.latitude = latitude
        self.longitude = longitude
        self.date = date
    }
}

/// "I was around this map cell on this day." The only thing that is shared.
public struct Sighting: Sendable, Hashable {
    /// Geohash of the map cell.
    public let cell: String
    /// Day number, see `SolarDay`.
    public let day: Int

    public init(cell: String, day: Int) {
        self.cell = cell
        self.day = day
    }
}

/// One person's list of sightings.
public struct Trail: Sendable, Equatable {
    public static let defaultPrecision = 7

    public var name: String
    public var precision: Int
    public var sightings: [Sighting]

    public init(name: String, precision: Int = Trail.defaultPrecision, sightings: [Sighting]) {
        self.name = name
        self.precision = precision
        self.sightings = sightings
    }

    public var dayRange: ClosedRange<Int>? {
        guard let first = sightings.map(\.day).min(), let last = sightings.map(\.day).max() else {
            return nil
        }
        return first...last
    }
}

/// Days are counted by the sun at the place of the photo, not by a time zone:
/// the clock is shifted by one hour per 15 degrees of longitude. Two phones
/// then agree on the day of a photo whatever their own time zone is.
public enum SolarDay {
    public static func day(for date: Date, longitude: Double) -> Int {
        let shifted = date.timeIntervalSince1970 + longitude / 15 * 3600
        return Int((shifted / 86_400).rounded(.down))
    }

    /// Midnight UTC of that day number. Format it in UTC to print the day.
    public static func date(for day: Int) -> Date {
        Date(timeIntervalSince1970: Double(day) * 86_400)
    }

    /// Day number of a calendar date such as 2018-03-17.
    public static func day(year: Int, month: Int, day: Int) -> Int? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = DateComponents(year: year, month: month, day: day)
        guard let date = calendar.date(from: components) else { return nil }
        return Int((date.timeIntervalSince1970 / 86_400).rounded(.down))
    }
}

public enum Reducer {
    /// Turns photo points into unique sightings, sorted by day then cell.
    /// Points without a usable location are dropped.
    public static func reduce(
        _ points: [PhotoPoint],
        precision: Int = Trail.defaultPrecision
    ) -> [Sighting] {
        var seen = Set<Sighting>()
        for point in points {
            guard isUsable(latitude: point.latitude, longitude: point.longitude) else { continue }
            seen.insert(
                Sighting(
                    cell: Geohash.encode(
                        latitude: point.latitude,
                        longitude: point.longitude,
                        precision: precision
                    ),
                    day: SolarDay.day(for: point.date, longitude: point.longitude)
                )
            )
        }
        return seen.sorted { ($0.day, $0.cell) < ($1.day, $1.cell) }
    }

    static func isUsable(latitude: Double, longitude: Double) -> Bool {
        guard latitude.isFinite, longitude.isFinite else { return false }
        guard abs(latitude) <= 90, abs(longitude) <= 180 else { return false }
        // (0, 0) is what broken metadata looks like, not a place people photograph.
        return !(latitude == 0 && longitude == 0)
    }
}
