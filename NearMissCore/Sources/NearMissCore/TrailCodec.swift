import Foundation

/// The file two people exchange. JSON, grouped by cell to stay small:
/// `{"cells":{"9g3w81t":[17607,17612]},"format":"near-miss","name":"Ana","precision":7,"version":1}`
public enum TrailCodec {
    public static let fileExtension = "nearmiss"
    public static let maxSightings = 1_000_000
    public static let maxNameLength = 40

    public enum DecodingFailure: Error, Equatable {
        case notATrail
        case unsupportedVersion(Int)
        case invalidCell(String)
        case tooLarge
    }

    private struct File: Codable {
        let format: String
        let version: Int
        let name: String
        let precision: Int
        let cells: [String: [Int]]
    }

    public static func encode(_ trail: Trail) throws -> Data {
        var cells: [String: Set<Int>] = [:]
        for sighting in trail.sightings {
            cells[sighting.cell, default: []].insert(sighting.day)
        }
        let file = File(
            format: "near-miss",
            version: 1,
            name: String(trail.name.prefix(maxNameLength)),
            precision: trail.precision,
            cells: cells.mapValues { $0.sorted() }
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(file)
    }

    /// The file comes from someone else's phone, so nothing in it is trusted.
    public static func decode(_ data: Data) throws -> Trail {
        guard let file = try? JSONDecoder().decode(File.self, from: data),
              file.format == "near-miss"
        else {
            throw DecodingFailure.notATrail
        }
        guard file.version == 1 else {
            throw DecodingFailure.unsupportedVersion(file.version)
        }
        guard (1...12).contains(file.precision) else {
            throw DecodingFailure.notATrail
        }

        var sightings: [Sighting] = []
        for (cell, days) in file.cells {
            guard cell.count == file.precision, Geohash.isValid(cell) else {
                throw DecodingFailure.invalidCell(String(cell.prefix(16)))
            }
            guard sightings.count + days.count <= maxSightings else {
                throw DecodingFailure.tooLarge
            }
            for day in Set(days) {
                sightings.append(Sighting(cell: cell, day: day))
            }
        }
        sightings.sort { ($0.day, $0.cell) < ($1.day, $1.cell) }

        let name = file.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return Trail(
            name: String(name.prefix(maxNameLength)),
            precision: file.precision,
            sightings: sightings
        )
    }
}
