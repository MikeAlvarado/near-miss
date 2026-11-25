import Foundation
import NearMissCore
import Photos

/// Reads the date and the place of every item in the photo library.
/// It never asks for image data, and nothing here touches the network.
enum PhotoScanner {
    struct Output: Sendable {
        let points: [PhotoPoint]
        let total: Int
    }

    enum Failure: Error {
        case denied
    }

    static func scan() async throws -> Output {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard status == .authorized || status == .limited else { throw Failure.denied }

        return await Task.detached(priority: .userInitiated) {
            let assets = PHAsset.fetchAssets(with: nil)
            var points: [PhotoPoint] = []
            assets.enumerateObjects { asset, _, _ in
                guard let date = asset.creationDate,
                      let coordinate = asset.location?.coordinate
                else { return }
                points.append(
                    PhotoPoint(
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude,
                        date: date
                    )
                )
            }
            return Output(points: points, total: assets.count)
        }.value
    }
}
