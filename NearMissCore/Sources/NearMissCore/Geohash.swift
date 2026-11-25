import Foundation

/// A point on the globe, in degrees.
public struct Coordinate: Sendable, Equatable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// Standard geohash: a short string that names a rectangle of the map.
/// At precision 7 a cell is about 150 m on a side.
public enum Geohash {
    static let alphabet = Array("0123456789bcdefghjkmnpqrstuvwxyz")
    static let values: [Character: Int] = Dictionary(
        uniqueKeysWithValues: alphabet.enumerated().map { ($1, $0) }
    )

    public static func encode(latitude: Double, longitude: Double, precision: Int) -> String {
        var lat = (min: -90.0, max: 90.0)
        var lon = (min: -180.0, max: 180.0)
        var hash = ""
        var bits = 0
        var value = 0
        var isLongitude = true

        while hash.count < precision {
            if isLongitude {
                let mid = (lon.min + lon.max) / 2
                if longitude >= mid {
                    value = value << 1 | 1
                    lon.min = mid
                } else {
                    value <<= 1
                    lon.max = mid
                }
            } else {
                let mid = (lat.min + lat.max) / 2
                if latitude >= mid {
                    value = value << 1 | 1
                    lat.min = mid
                } else {
                    value <<= 1
                    lat.max = mid
                }
            }
            isLongitude.toggle()
            bits += 1
            if bits == 5 {
                hash.append(alphabet[value])
                bits = 0
                value = 0
            }
        }
        return hash
    }

    /// The center of a cell, or nil when the string is not a geohash.
    public static func center(of hash: String) -> Coordinate? {
        guard !hash.isEmpty else { return nil }
        var lat = (min: -90.0, max: 90.0)
        var lon = (min: -180.0, max: 180.0)
        var isLongitude = true

        for character in hash {
            guard let value = values[character] else { return nil }
            for shift in stride(from: 4, through: 0, by: -1) {
                let bit = (value >> shift) & 1
                if isLongitude {
                    let mid = (lon.min + lon.max) / 2
                    if bit == 1 { lon.min = mid } else { lon.max = mid }
                } else {
                    let mid = (lat.min + lat.max) / 2
                    if bit == 1 { lat.min = mid } else { lat.max = mid }
                }
                isLongitude.toggle()
            }
        }
        return Coordinate(
            latitude: (lat.min + lat.max) / 2,
            longitude: (lon.min + lon.max) / 2
        )
    }

    public static func isValid(_ hash: String) -> Bool {
        !hash.isEmpty && hash.allSatisfy { values[$0] != nil }
    }
}
