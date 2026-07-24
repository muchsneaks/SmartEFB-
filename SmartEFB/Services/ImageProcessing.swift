import UIKit

/// Helpers for preparing a captured image for upload to the vision API.
enum ImageProcessing {
    /// Downscales the image to a sensible maximum dimension and encodes it as
    /// JPEG, keeping the upload small while preserving table legibility.
    static func jpegForUpload(_ image: UIImage, maxDimension: CGFloat = 1600, quality: CGFloat = 0.8) -> Data? {
        let resized = downscaled(image, maxDimension: maxDimension)
        return resized.jpegData(compressionQuality: quality)
    }

    private static func downscaled(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let largestSide = max(size.width, size.height)
        guard largestSide > maxDimension else { return image }

        let scale = maxDimension / largestSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
