import XCTest

@testable import NearMissCore

final class GeohashTests: XCTestCase {
    func testEncodesKnownVectors() {
        XCTAssertEqual(Geohash.encode(latitude: 57.64911, longitude: 10.40744, precision: 11), "u4pruydqqvj")
        XCTAssertEqual(Geohash.encode(latitude: 42.6, longitude: -5.6, precision: 5), "ezs42")
    }

    func testCenterIsInsideTheCell() throws {
        let center = try XCTUnwrap(Geohash.center(of: "ezs42"))
        XCTAssertEqual(center.latitude, 42.605, accuracy: 0.001)
        XCTAssertEqual(center.longitude, -5.603, accuracy: 0.001)
        XCTAssertEqual(
            Geohash.encode(latitude: center.latitude, longitude: center.longitude, precision: 5),
            "ezs42"
        )
    }

    func testRejectsStringsThatAreNotGeohashes() {
        XCTAssertNil(Geohash.center(of: ""))
        XCTAssertNil(Geohash.center(of: "abc"))  // "a" is not in the alphabet
        XCTAssertFalse(Geohash.isValid("9g3w81L"))
        XCTAssertTrue(Geohash.isValid("9g3w81t"))
    }
}

final class ReducerTests: XCTestCase {
    private func date(_ iso: String) -> Date {
        ISO8601DateFormatter().date(from: iso)!
    }

    func testPhotosInTheSameCellAndDayCollapseToOneSighting() {
        let points = [
            PhotoPoint(latitude: 19.43520, longitude: -99.14120, date: date("2018-03-17T18:00:00Z")),
            PhotoPoint(latitude: 19.43521, longitude: -99.14121, date: date("2018-03-17T20:30:00Z")),
            PhotoPoint(latitude: 19.43520, longitude: -99.14120, date: date("2018-03-18T18:00:00Z")),
        ]
        let sightings = Reducer.reduce(points)
        XCTAssertEqual(sightings.count, 2)
        XCTAssertEqual(sightings[0].cell, sightings[1].cell)
        XCTAssertEqual(sightings[0].cell.count, 7)
        XCTAssertEqual(sightings[1].day - sightings[0].day, 1)
    }

    func testDropsUnusableLocations() {
        let now = Date(timeIntervalSince1970: 1_500_000_000)
        let points = [
            PhotoPoint(latitude: 0, longitude: 0, date: now),
            PhotoPoint(latitude: .nan, longitude: 10, date: now),
            PhotoPoint(latitude: 95, longitude: 10, date: now),
            PhotoPoint(latitude: 10, longitude: 200, date: now),
        ]
        XCTAssertTrue(Reducer.reduce(points).isEmpty)
    }

    func testDayFollowsTheSunNotTheDeviceTimeZone() {
        // 03:00 UTC on March 18 is still the evening of March 17 in Mexico City.
        let evening = date("2018-03-18T03:00:00Z")
        let march17 = SolarDay.day(year: 2018, month: 3, day: 17)
        XCTAssertEqual(SolarDay.day(for: evening, longitude: -99.14), march17)
        // The same instant in Tokyo is already midday on March 18.
        XCTAssertEqual(SolarDay.day(for: evening, longitude: 139.7), march17! + 1)
    }

    func testDayRoundTripsToADate() {
        let day = SolarDay.day(year: 2018, month: 3, day: 17)!
        XCTAssertEqual(SolarDay.date(for: day), date("2018-03-17T00:00:00Z"))
    }
}

final class TrailCodecTests: XCTestCase {
    func testRoundTrip() throws {
        let data = try TrailCodec.encode(DemoData.ana)
        XCTAssertEqual(try TrailCodec.decode(data), DemoData.ana)
    }

    func testFileHasNoExactCoordinates() throws {
        let text = String(decoding: try TrailCodec.encode(DemoData.ana), as: UTF8.self)
        XCTAssertFalse(text.contains("19.4"))
        XCTAssertFalse(text.contains("-99."))
        XCTAssertTrue(text.contains("\"format\":\"near-miss\""))
    }

    func testEncodingIsStable() throws {
        XCTAssertEqual(try TrailCodec.encode(DemoData.beto), try TrailCodec.encode(DemoData.beto))
    }

    func testRejectsOtherFiles() {
        let notJSON = Data("hello".utf8)
        let otherJSON = Data(#"{"format":"something-else","version":1,"name":"x","precision":7,"cells":{}}"#.utf8)
        XCTAssertThrowsError(try TrailCodec.decode(notJSON)) {
            XCTAssertEqual($0 as? TrailCodec.DecodingFailure, .notATrail)
        }
        XCTAssertThrowsError(try TrailCodec.decode(otherJSON)) {
            XCTAssertEqual($0 as? TrailCodec.DecodingFailure, .notATrail)
        }
    }

    func testRejectsNewerVersionsAndBadCells() {
        let newer = Data(#"{"format":"near-miss","version":2,"name":"x","precision":7,"cells":{}}"#.utf8)
        let badCell = Data(#"{"format":"near-miss","version":1,"name":"x","precision":7,"cells":{"not a cell":[1]}}"#.utf8)
        let wrongLength = Data(#"{"format":"near-miss","version":1,"name":"x","precision":7,"cells":{"9g3w":[1]}}"#.utf8)
        XCTAssertThrowsError(try TrailCodec.decode(newer)) {
            XCTAssertEqual($0 as? TrailCodec.DecodingFailure, .unsupportedVersion(2))
        }
        XCTAssertThrowsError(try TrailCodec.decode(badCell))
        XCTAssertThrowsError(try TrailCodec.decode(wrongLength))
    }

    func testTrimsLongNamesAndDuplicateDays() throws {
        let long = String(repeating: "a", count: 200)
        let data = Data(#"{"format":"near-miss","version":1,"name":"\#(long)","precision":7,"cells":{"9g3w81t":[5,5,6]}}"#.utf8)
        let trail = try TrailCodec.decode(data)
        XCTAssertEqual(trail.name.count, TrailCodec.maxNameLength)
        XCTAssertEqual(trail.sightings.count, 2)
    }
}

final class MatcherTests: XCTestCase {
    private func sighting(_ latitude: Double, _ longitude: Double, day: Int) -> Sighting {
        Sighting(cell: Geohash.encode(latitude: latitude, longitude: longitude, precision: 7), day: day)
    }

    func testDistanceBetweenCellsIsRoughlyRight() {
        // 0.01 degrees of latitude is about 1.11 km.
        let a = [sighting(19.40, -99.15, day: 100)]
        let b = [sighting(19.41, -99.15, day: 100)]
        let result = Matcher.compare(mine: a, theirs: b, tolerance: Tolerance(meters: 5000, days: 0))
        XCTAssertEqual(result.matches.count, 1)
        XCTAssertEqual(result.matches[0].meters, 1112, accuracy: 160)
    }

    func testSamePlaceSameDayIsAMatch() {
        let a = [sighting(19.4352, -99.1412, day: 100)]
        let b = [sighting(19.4360, -99.1440, day: 100)]
        let result = Matcher.compare(mine: a, theirs: b, tolerance: Tolerance())
        XCTAssertEqual(result.matches.count, 1)
        XCTAssertEqual(result.matches[0].dayGap, 0)
        XCTAssertLessThan(result.matches[0].meters, 500)
        XCTAssertEqual(result.closest, result.matches[0])
    }

    func testDayToleranceWidensTheMatch() {
        let a = [sighting(19.4326, -99.1332, day: 100)]
        let b = [sighting(19.4333, -99.1340, day: 101)]
        XCTAssertTrue(Matcher.compare(mine: a, theirs: b, tolerance: Tolerance(meters: 500, days: 0)).matches.isEmpty)
        XCTAssertEqual(Matcher.compare(mine: a, theirs: b, tolerance: Tolerance(meters: 500, days: 1)).matches.count, 1)
    }

    func testDistanceToleranceWidensTheMatch() {
        let a = [sighting(19.4352, -99.1412, day: 100)]
        let b = [sighting(19.4362, -99.1602, day: 100)]  // about 2 km west
        XCTAssertTrue(Matcher.compare(mine: a, theirs: b, tolerance: Tolerance(meters: 500, days: 0)).matches.isEmpty)
        XCTAssertEqual(Matcher.compare(mine: a, theirs: b, tolerance: Tolerance(meters: 5000, days: 0)).matches.count, 1)
    }

    func testWithoutMatchesTheClosestPairIsStillReported() throws {
        let a = [
            sighting(19.4352, -99.1412, day: 100),
            sighting(20.6767, -103.3475, day: 400),
        ]
        let b = [
            sighting(25.6694, -100.3099, day: 90),  // far, 10 days
            sighting(19.4362, -99.1602, day: 103),  // 2 km, 3 days
            sighting(19.0437, -98.1981, day: 400),  // same day as Guadalajara but 500+ km away
        ]
        let result = Matcher.compare(mine: a, theirs: b, tolerance: Tolerance())
        XCTAssertTrue(result.matches.isEmpty)
        let closest = try XCTUnwrap(result.closest)
        XCTAssertEqual(closest.mine.day, 100)
        XCTAssertEqual(closest.theirs.day, 103)
        XCTAssertEqual(closest.dayGap, 3)
        XCTAssertEqual(closest.meters, 2000, accuracy: 250)
    }

    func testClosestAgreesWithBruteForce() throws {
        var generator = SplitMix(seed: 42)
        func randomTrail(count: Int) -> [Sighting] {
            (0..<count).map { _ in
                sighting(
                    Double.random(in: 19.0...21.0, using: &generator),
                    Double.random(in: -100.0...(-98.0), using: &generator),
                    day: Int.random(in: 0...3000, using: &generator)
                )
            }
        }
        let a = randomTrail(count: 120)
        let b = randomTrail(count: 120)

        let pa = Matcher.points(from: a, beforeDay: nil)
        let pb = Matcher.points(from: b, beforeDay: nil)
        var expected: NearMiss?
        for p in pa {
            for q in pb {
                let candidate = Matcher.nearMiss(p, q, meters: Matcher.distance(p, q))
                if expected.map({ Matcher.isCloser(candidate, $0) }) ?? true { expected = candidate }
            }
        }
        // A tolerance nothing can meet, so the result comes from the pruned search.
        let result = Matcher.compare(mine: a, theirs: b, tolerance: Tolerance(meters: 0, days: 0))
        XCTAssertEqual(result.closest, try XCTUnwrap(expected))
    }

    func testOneMatchPerDayEvenWithManyCells() {
        // Both wander through several cells of the same neighborhood on one day.
        let a = (0..<5).map { sighting(19.4352 + Double($0) * 0.0015, -99.1412, day: 100) }
        let b = (0..<5).map { sighting(19.4352 + Double($0) * 0.0015, -99.1420, day: 100) }
        let result = Matcher.compare(mine: a, theirs: b, tolerance: Tolerance())
        XCTAssertEqual(result.matches.count, 1)
    }

    func testOnlySightingsBeforeTheDayTheyMetCount() {
        let a = [sighting(19.4352, -99.1412, day: 100), sighting(19.4352, -99.1412, day: 500)]
        let b = [sighting(19.4352, -99.1412, day: 100), sighting(19.4352, -99.1412, day: 500)]
        XCTAssertEqual(Matcher.compare(mine: a, theirs: b, tolerance: Tolerance()).matches.count, 2)
        XCTAssertEqual(
            Matcher.compare(mine: a, theirs: b, tolerance: Tolerance(), beforeDay: 500).matches.map(\.mine.day),
            [100]
        )
    }

    func testEmptyTrailGivesNothing() {
        let a = [sighting(19.4352, -99.1412, day: 100)]
        let result = Matcher.compare(mine: a, theirs: [], tolerance: Tolerance())
        XCTAssertTrue(result.matches.isEmpty)
        XCTAssertNil(result.closest)
    }

    func testMatchesComeOldestFirst() {
        let a = [sighting(19.4352, -99.1412, day: 300), sighting(19.4352, -99.1412, day: 100)]
        let b = [sighting(19.4352, -99.1412, day: 100), sighting(19.4352, -99.1412, day: 300)]
        let result = Matcher.compare(mine: a, theirs: b, tolerance: Tolerance())
        XCTAssertEqual(result.matches.map(\.mine.day), [100, 300])
    }
}

final class DemoDataTests: XCTestCase {
    func testAnaAndBetoAlmostMetTwiceOnTheSameDay() {
        let result = Matcher.compare(
            mine: DemoData.ana.sightings,
            theirs: DemoData.beto.sightings,
            tolerance: Tolerance()
        )
        XCTAssertEqual(result.matches.count, 2)
        XCTAssertTrue(result.matches.allSatisfy { $0.dayGap == 0 && $0.meters <= 500 })
    }

    func testAnaAndBetoGetAThirdWithOneDayOfSlack() {
        let result = Matcher.compare(
            mine: DemoData.ana.sightings,
            theirs: DemoData.beto.sightings,
            tolerance: Tolerance(meters: 500, days: 1)
        )
        XCTAssertEqual(result.matches.count, 3)
    }

    func testAnaAndCarlaNeverMetButCameClose() throws {
        let result = Matcher.compare(
            mine: DemoData.ana.sightings,
            theirs: DemoData.carla.sightings,
            tolerance: Tolerance()
        )
        XCTAssertTrue(result.matches.isEmpty)
        let closest = try XCTUnwrap(result.closest)
        XCTAssertEqual(closest.dayGap, 3)
        XCTAssertEqual(closest.meters, 2000, accuracy: 250)
        XCTAssertEqual(closest.mine.day, SolarDay.day(year: 2018, month: 3, day: 17))
    }
}

/// Small seeded generator so the random test is the same on every run.
struct SplitMix: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
