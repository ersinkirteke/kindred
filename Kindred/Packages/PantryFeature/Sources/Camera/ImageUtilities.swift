import CoreImage
import UIKit

extension UIImage {
    /// Calculate image sharpness using Laplacian variance blur detection
    /// Returns variance value - lower values indicate blurrier images
    /// Threshold: variance < 100 typically indicates blurry image
    func calculateSharpness() -> Double? {
        autoreleasepool {
            guard let ciImage = CIImage(image: self) else { return nil }

            let context = CIContext()

            // Convert to grayscale for better blur detection
            guard let grayscaleFilter = CIFilter(name: "CIPhotoEffectMono") else { return nil }
            grayscaleFilter.setValue(ciImage, forKey: kCIInputImageKey)
            guard let grayscale = grayscaleFilter.outputImage else { return nil }

            // Sample center region for performance (not full image)
            let rect = grayscale.extent
            let centerRect = CGRect(
                x: rect.width / 4,
                y: rect.height / 4,
                width: rect.width / 2,
                height: rect.height / 2
            )
            let croppedImage = grayscale.cropped(to: centerRect)

            // Apply Laplacian kernel for edge detection
            // Laplacian kernel: [0,-1,0,-1,4,-1,0,-1,0]
            guard let convolutionFilter = CIFilter(name: "CIConvolution3X3") else { return nil }
            let weights = CIVector(values: [0, -1, 0, -1, 4, -1, 0, -1, 0], count: 9)
            convolutionFilter.setValue(croppedImage, forKey: kCIInputImageKey)
            convolutionFilter.setValue(weights, forKey: "inputWeights")

            guard let outputImage = convolutionFilter.outputImage,
                  let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
                return nil
            }

            // Calculate variance from output
            let width = cgImage.width
            let height = cgImage.height
            let bytesPerRow = cgImage.bytesPerRow
            let bitsPerPixel = cgImage.bitsPerPixel
            let bytesPerPixel = bitsPerPixel / 8

            guard let data = cgImage.dataProvider?.data,
                  let bytes = CFDataGetBytePtr(data) else {
                return nil
            }

            var sum: Double = 0
            var sumSquared: Double = 0
            var count: Double = 0

            for y in 0..<height {
                for x in 0..<width {
                    let offset = y * bytesPerRow + x * bytesPerPixel
                    let pixelValue = Double(bytes[offset])
                    sum += pixelValue
                    sumSquared += pixelValue * pixelValue
                    count += 1
                }
            }

            let mean = sum / count
            let variance = (sumSquared / count) - (mean * mean)

            return variance
        }
    }

    /// Compress image for upload with dimension scaling and JPEG compression
    /// - Parameters:
    ///   - maxDimension: Maximum width or height (default 2048 for 48MP camera safety)
    ///   - quality: JPEG compression quality 0.0-1.0 (default 0.8)
    /// - Returns: Compressed JPEG data
    func compressForUpload(maxDimension: CGFloat = 2048, quality: CGFloat = 0.8) -> Data? {
        autoreleasepool {
            let currentSize = max(size.width, size.height)

            // If image is small enough, just compress
            if currentSize <= maxDimension {
                return jpegData(compressionQuality: quality)
            }

            // Calculate scaled size maintaining aspect ratio
            let scale = maxDimension / currentSize
            let newSize = CGSize(
                width: size.width * scale,
                height: size.height * scale
            )

            // Use UIGraphicsImageRenderer for efficient scaling
            let renderer = UIGraphicsImageRenderer(size: newSize)
            let scaledImage = renderer.image { context in
                draw(in: CGRect(origin: .zero, size: newSize))
            }

            return scaledImage.jpegData(compressionQuality: quality)
        }
    }
}
