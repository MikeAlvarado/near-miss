import Foundation
import NearMissCore
import Observation

@MainActor
@Observable
final class AppModel {
    enum ScanState: Equatable {
        case idle
        case scanning
        case denied
        /// `total` photos and videos in the library, `located` of them with a place.
        case done(total: Int, located: Int)
    }

    enum Demo: String {
        case match
        case noMatch
    }

    private(set) var myTrail: Trail?
    private(set) var partnerTrail: Trail?
    private(set) var demo: Demo?
    private(set) var scanState: ScanState = .idle
    private(set) var comparison: Comparison?
    var importMessage: String?

    var myName: String = UserDefaults.standard.string(forKey: "myName") ?? "" {
        didSet { UserDefaults.standard.set(myName, forKey: "myName") }
    }

    var tolerance = Tolerance() { didSet { recompute() } }
    var onlyBeforeMeeting = false { didSet { recompute() } }
    var metDate = Date() { didSet { recompute() } }

    private var compareTask: Task<Void, Never>?

    init() {
        myTrail = Self.load("mine")
        partnerTrail = Self.load("partner")
    }

    var canCompare: Bool { myTrail != nil && partnerTrail != nil }

    var partnerName: String {
        let name = partnerTrail?.name ?? ""
        return name.isEmpty ? L("tu pareja", "your partner") : name
    }

    // MARK: - My trail

    func scanPhotos() async {
        scanState = .scanning
        do {
            let output = try await PhotoScanner.scan()
            let sightings = await Task.detached { Reducer.reduce(output.points) }.value
            leaveDemo()
            myTrail = Trail(name: myName, sightings: sightings)
            Self.save(myTrail, as: "mine")
            scanState = .done(total: output.total, located: output.points.count)
        } catch {
            scanState = .denied
        }
    }

    /// Writes my trail to a temporary file for the share sheet.
    func exportFile() -> URL? {
        guard var trail = myTrail else { return nil }
        if demo == nil { trail.name = myName.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard let data = try? TrailCodec.encode(trail) else { return nil }
        let slug = trail.name.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        let fileName = (slug.isEmpty ? L("mi-rastro", "my-trail") : L("rastro-", "trail-") + slug) + "." + TrailCodec.fileExtension
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    // MARK: - Partner's trail

    func importPartner(from url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        guard size <= 50_000_000, let data = try? Data(contentsOf: url) else {
            importMessage = L("No se pudo leer ese archivo.", "That file could not be read.")
            return
        }
        do {
            let trail = try TrailCodec.decode(data)
            if let mine = myTrail, demo == nil, mine.sightings == trail.sightings, !mine.sightings.isEmpty {
                importMessage = L("Ese es tu propio rastro. Pídele a tu pareja el suyo.", "That is your own trail. Ask your partner for theirs.")
                return
            }
            leaveDemo()
            partnerTrail = trail
            Self.save(trail, as: "partner")
            importMessage = nil
            recompute()
        } catch TrailCodec.DecodingFailure.unsupportedVersion {
            importMessage = L("Ese rastro viene de una versión más nueva de la app.", "That trail comes from a newer version of the app.")
        } catch {
            importMessage = L("Ese archivo no es un rastro de Near Miss.", "That file is not a Near Miss trail.")
        }
    }

    // MARK: - Demo

    func startDemo(_ kind: Demo) {
        demo = kind
        myTrail = DemoData.ana
        partnerTrail = kind == .match ? DemoData.beto : DemoData.carla
        scanState = .idle
        tolerance = Tolerance()
        onlyBeforeMeeting = false
        recompute()
    }

    func leaveDemo() {
        guard demo != nil else { return }
        demo = nil
        myTrail = Self.load("mine")
        partnerTrail = Self.load("partner")
        scanState = .idle
        recompute()
    }

    // MARK: - Comparison

    /// The day the two met, when only earlier days should count.
    var beforeDay: Int? {
        onlyBeforeMeeting ? Self.dayNumber(of: metDate) : nil
    }

    func recompute() {
        compareTask?.cancel()
        guard let mine = myTrail?.sightings, let theirs = partnerTrail?.sightings else {
            comparison = nil
            return
        }
        let tolerance = tolerance
        let beforeDay = beforeDay
        compareTask = Task {
            let result = await Task.detached(priority: .userInitiated) {
                Matcher.compare(mine: mine, theirs: theirs, tolerance: tolerance, beforeDay: beforeDay)
            }.value
            if !Task.isCancelled { comparison = result }
        }
    }

    static func dayNumber(of date: Date) -> Int? {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        guard let year = parts.year, let month = parts.month, let day = parts.day else { return nil }
        return SolarDay.day(year: year, month: month, day: day)
    }

    // MARK: - Storage (inside the app's own folder, on this device)

    private static func fileURL(_ name: String) -> URL? {
        guard let folder = try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        ) else { return nil }
        return folder.appendingPathComponent(name + "." + TrailCodec.fileExtension)
    }

    private static func load(_ name: String) -> Trail? {
        guard let url = fileURL(name), let data = try? Data(contentsOf: url) else { return nil }
        return try? TrailCodec.decode(data)
    }

    private static func save(_ trail: Trail?, as name: String) {
        guard let url = fileURL(name), let trail, let data = try? TrailCodec.encode(trail) else { return }
        try? data.write(to: url, options: [.atomic, .completeFileProtection])
    }
}
