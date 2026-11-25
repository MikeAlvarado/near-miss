import Foundation

/// Made-up people for the demo mode and the tests. The places are public
/// landmarks in Mexico; the visits never happened.
public enum DemoData {
    /// "You" in both demo scenarios.
    public static let ana = trail(
        name: "Ana",
        visits: [
            (19.4326, -99.1332, "2016-09-15"),  // Zócalo
            (19.3500, -99.1620, "2017-05-06"),  // Coyoacán
            (19.4352, -99.1412, "2018-03-17"),  // Bellas Artes
            (17.0657, -96.7233, "2018-11-02"),  // Oaxaca
            (19.4249, -99.1947, "2019-06-22"),  // Auditorio Nacional
            (20.6767, -103.3475, "2019-12-28"),  // Guadalajara
        ]
    )

    /// Crosses paths with Ana: twice on the same day, once a day late.
    public static let beto = trail(
        name: "Beto",
        visits: [
            (19.4333, -99.1340, "2016-09-16"),  // Zócalo, the day after Ana
            (19.4270, -99.1677, "2017-08-12"),  // Ángel de la Independencia
            (19.4360, -99.1440, "2018-03-17"),  // Alameda, next to Bellas Artes
            (19.4256, -99.1925, "2019-06-22"),  // outside the Auditorio
            (20.6409, -103.2933, "2019-12-30"),  // Tlaquepaque
        ]
    )

    /// Never within 500 m of Ana on the same day. Closest: about 2 km, 3 days apart.
    public static let carla = trail(
        name: "Carla",
        visits: [
            (25.6694, -100.3099, "2015-07-04"),  // Monterrey
            (19.0437, -98.1981, "2017-01-21"),  // Puebla
            (19.4362, -99.1602, "2018-03-20"),  // 2 km west of Bellas Artes, 3 days later
            (19.4204, -99.1819, "2019-07-20"),  // Chapultepec
        ]
    )

    static func trail(name: String, visits: [(Double, Double, String)]) -> Trail {
        let points = visits.compactMap { latitude, longitude, date -> PhotoPoint? in
            let parts = date.split(separator: "-").compactMap { Int($0) }
            guard parts.count == 3,
                  let day = SolarDay.day(year: parts[0], month: parts[1], day: parts[2])
            else { return nil }
            // 18:00 UTC is around noon in Mexico, safely inside the solar day.
            let noon = SolarDay.date(for: day).addingTimeInterval(18 * 3600)
            return PhotoPoint(latitude: latitude, longitude: longitude, date: noon)
        }
        return Trail(name: name, sightings: Reducer.reduce(points))
    }
}
