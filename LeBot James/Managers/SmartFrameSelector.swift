import Foundation
import ARKit
import Vision

class SmartFrameSelector {
    // MARK: - Public Methods
    func selectFrames(from shotEvent: ShotEvent, currentFrame: CVPixelBuffer, completion: @escaping ([CVPixelBuffer]) -> Void) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            var selectedFrames: [CVPixelBuffer] = []
            
            // Select release frame for form analysis
            if let releaseFrame = shotEvent.releaseFrame {
                selectedFrames.append(releaseFrame)
            }
            
            // Select impact frame for outcome analysis
            if let impactFrame = shotEvent.impactFrame {
                selectedFrames.append(impactFrame)
            }
            
            // If we don't have good frames from the event, use current frame
            if selectedFrames.isEmpty {
                selectedFrames.append(currentFrame)
            }
            
            // Quality check - ensure frames are clear and well-lit
            let qualityFilteredFrames = self.filterFramesByQuality(selectedFrames)
            
            DispatchQueue.main.async {
                completion(qualityFilteredFrames)
            }
        }
    }
    
    // MARK: - Private Methods
    private func filterFramesByQuality(_ frames: [CVPixelBuffer]) -> [CVPixelBuffer] {
        var filteredFrames: [CVPixelBuffer] = []
        
        for frame in frames {
            if isFrameGoodQuality(frame) {
                filteredFrames.append(frame)
            }
        }
        
        // If no frames pass quality check, return original frames
        return filteredFrames.isEmpty ? frames : filteredFrames
    }
    
    private func isFrameGoodQuality(_ frame: CVPixelBuffer) -> Bool {
        // Check basic quality metrics
        let width = CVPixelBufferGetWidth(frame)
        let height = CVPixelBufferGetHeight(frame)
        
        // Ensure minimum resolution
        guard width >= 640 && height >= 480 else { return false }
        
        // Check brightness (simplified)
        let brightness = calculateBrightness(frame)
        
        // Reject frames that are too dark or too bright
        return brightness > 0.1 && brightness < 0.9
    }
    
    private func calculateBrightness(_ frame: CVPixelBuffer) -> Float {
        CVPixelBufferLockBaseAddress(frame, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(frame, .readOnly) }
        
        let width = CVPixelBufferGetWidth(frame)
        let height = CVPixelBufferGetHeight(frame)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(frame) else { return 0.5 }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(frame)
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        var totalBrightness: Int = 0
        let sampleStep = 10 // Sample every 10th pixel for performance
        
        for y in stride(from: 0, to: height, by: sampleStep) {
            for x in stride(from: 0, to: width, by: sampleStep) {
                let pixelIndex = y * bytesPerRow + x * 4 // Assuming BGRA format
                
                if pixelIndex + 2 < bytesPerRow * height {
                    let b = Int(buffer[pixelIndex])
                    let g = Int(buffer[pixelIndex + 1])
                    let r = Int(buffer[pixelIndex + 2])
                    
                    // Calculate luminance
                    let luminance = Int(0.299 * Float(r) + 0.587 * Float(g) + 0.114 * Float(b))
                    totalBrightness += luminance
                }
            }
        }
        
        let sampledPixels = (width / sampleStep) * (height / sampleStep)
        let averageBrightness = Float(totalBrightness) / Float(sampledPixels)
        
        return averageBrightness / 255.0
    }
}