import Foundation
import UIKit
import CoreMedia
import VideoToolbox
import CoreImage

// MARK: - Image Conversion Utilities
struct ImageConversionUtils {
    
    // MARK: - CMSampleBuffer to UIImage Conversion
    static func convertSampleBufferToUIImage(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("❌ Failed to get pixel buffer from sample buffer")
            return nil
        }
        
        // Create CIImage from pixel buffer
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Create CIContext for rendering (use GPU acceleration when available)
        let context = CIContext(options: [.useSoftwareRenderer: false])
        
        // Render to CGImage
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("❌ Failed to create CGImage from CIImage")
            return nil
        }
        
        // Convert to UIImage with proper orientation
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
    }
    
    // MARK: - CVPixelBuffer to UIImage Conversion
    static func convertPixelBufferToUIImage(_ pixelBuffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: [.useSoftwareRenderer: false])
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
    }
    
    // MARK: - Image Quality and Compression
    static func compressImageForAPI(_ image: UIImage, quality: CGFloat = 0.7) -> Data? {
        return image.jpegData(compressionQuality: quality)
    }
    
    // MARK: - Image Orientation Handling
    static func correctImageOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let correctedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return correctedImage ?? image
    }
    
    // MARK: - Error Handling
    enum ConversionError: Error {
        case invalidSampleBuffer
        case pixelBufferExtractionFailed
        case ciImageCreationFailed
        case cgImageCreationFailed
        case compressionFailed
        
        var localizedDescription: String {
            switch self {
            case .invalidSampleBuffer:
                return "Invalid sample buffer provided"
            case .pixelBufferExtractionFailed:
                return "Failed to extract pixel buffer from sample buffer"
            case .ciImageCreationFailed:
                return "Failed to create CIImage from pixel buffer"
            case .cgImageCreationFailed:
                return "Failed to create CGImage from CIImage"
            case .compressionFailed:
                return "Failed to compress image for API transmission"
            }
        }
    }
    
    // MARK: - Safe Conversion with Error Handling
    static func safeConvertSampleBufferToUIImage(_ sampleBuffer: CMSampleBuffer) -> Result<UIImage, ConversionError> {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return .failure(.pixelBufferExtractionFailed)
        }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: [.useSoftwareRenderer: false])
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return .failure(.cgImageCreationFailed)
        }
        
        let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
        return .success(uiImage)
    }
}

// MARK: - Extension for TrainingSessionManager
extension TrainingSessionManager {
    
    // Use the utility for image conversion
    func convertSampleBufferToUIImage(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
        return ImageConversionUtils.convertSampleBufferToUIImage(sampleBuffer)
    }
}