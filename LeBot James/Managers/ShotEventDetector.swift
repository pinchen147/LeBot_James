import Foundation
import ARKit
import Vision

class ShotEventDetector {
    // MARK: - Properties
    private var frameBuffer: [CVPixelBuffer] = []
    private let bufferSize = 30 // ~1 second at 30fps
    private var isProcessing = false
    private var lastMotionDetected: Date?
    private var pendingCompletion: ((ShotEvent) -> Void)?
    
    // Vision request for motion detection
    private lazy var motionRequest: VNDetectTrajectoriesRequest = {
        let request = VNDetectTrajectoriesRequest(
            frameAnalysisSpacing: .zero,
            trajectoryLength: 10,
            completionHandler: handleDetectedTrajectories
        )
        return request
    }()
    
    // MARK: - Public Methods
    func processFrame(_ frame: ARFrame, completion: @escaping (ShotEvent) -> Void) {
        processPixelBuffer(frame.capturedImage, completion: completion)
    }
    
    func processPixelBuffer(_ pixelBuffer: CVPixelBuffer, completion: @escaping (ShotEvent) -> Void) {
        // Add frame to buffer
        frameBuffer.append(pixelBuffer)
        
        // Keep buffer size manageable
        if frameBuffer.count > bufferSize {
            frameBuffer.removeFirst()
        }
        
        // Skip if already processing
        guard !isProcessing else { return }
        
        // Detect motion patterns that indicate a shot
        detectShotMotion(in: pixelBuffer) { [weak self] shotDetected in
            if shotDetected {
                self?.processShotEvent(completion: completion)
            }
        }
    }
    
    // MARK: - Private Methods
    private func detectShotMotion(in pixelBuffer: CVPixelBuffer, completion: @escaping (Bool) -> Void) {
        // Store the completion for use in the Vision completion handler
        self.pendingCompletion = { shotEvent in
            completion(true)
        }
        
        // Use Vision framework to detect motion
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        do {
            try handler.perform([motionRequest])
        } catch {
            print("Motion detection failed: \(error)")
            completion(false)
        }
    }
    
    // Vision completion handler
    private func handleDetectedTrajectories(for request: VNRequest, error: Error?) {
        if let error = error {
            print("Trajectory detection error: \(error)")
            return
        }
        
        guard let trajectories = request.results as? [VNTrajectoryObservation] else {
            return
        }
        
        // Check if motion pattern matches basketball shot
        let shotDetected = analyzeTrajectoriesForShot(trajectories)
        
        if shotDetected {
            // Process shot event
            DispatchQueue.main.async {
                if let completion = self.pendingCompletion {
                    self.processShotEvent(completion: { shotEvent in
                        completion(shotEvent)
                    })
                }
            }
        }
    }
    
    private func analyzeTrajectoriesForShot(_ trajectories: [VNTrajectoryObservation]) -> Bool {
        // Modern approach: calculate trajectory length from detected points
        for trajectory in trajectories {
            let points = trajectory.detectedPoints
            
            // Calculate trajectory length from detected points
            let calculatedLength = calculateTrajectoryLength(from: points)
            
            // Use calculated length to filter out insignificant motion
            guard calculatedLength > 0.3 else { continue }
            
            // Need at least 5 points to analyze trajectory
            guard points.count >= 5 else { continue }
            
            // Check for upward motion (decreasing y values, as y=0 is top of screen)
            let upwardMotion = hasUpwardMotion(points: points)
            
            // Check for parabolic motion (typical of basketball shots)
            let parabolicMotion = hasParabolicMotion(points: points)
            
            if upwardMotion && parabolicMotion {
                print("Shot detected! Trajectory length: \(calculatedLength)")
                return true
            }
        }
        
        return false
    }
    
    private func calculateTrajectoryLength(from points: [VNPoint]) -> Float {
        guard points.count >= 2 else { return 0 }
        
        var totalLength: Float = 0
        for i in 1..<points.count {
            let prevPoint = points[i-1]
            let currentPoint = points[i]
            
            let dx = currentPoint.x - prevPoint.x
            let dy = currentPoint.y - prevPoint.y
            
            totalLength += sqrt(Float(dx * dx + dy * dy))
        }
        
        return totalLength
    }
    
    private func hasUpwardMotion(points: [VNPoint]) -> Bool {
        guard points.count >= 3 else { return false }
        
        let firstThird = points.count / 3
        let startY = points[0].y
        let midY = points[firstThird].y
        
        // In Vision coordinates, y=0 is top, so upward motion means decreasing y
        return midY < startY
    }
    
    private func hasParabolicMotion(points: [VNPoint]) -> Bool {
        guard points.count >= 5 else { return false }
        
        let startY = points[0].y
        let midY = points[points.count / 2].y
        let endY = points.last!.y
        
        // Check for arc pattern: goes up then down
        return midY < startY && endY > midY
    }
    
    private func processShotEvent(completion: @escaping (ShotEvent) -> Void) {
        guard !isProcessing else { return }
        
        isProcessing = true
        
        // Create shot event from current frame buffer
        let shotEvent = ShotEvent(
            timestamp: Date(),
            pixelBuffers: frameBuffer,
            releaseFrameIndex: frameBuffer.count - 5, // Estimate release point
            impactFrameIndex: frameBuffer.count - 1   // Current frame as impact
        )
        
        // Reset processing state
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isProcessing = false
        }
        
        completion(shotEvent)
    }
}

// MARK: - Supporting Types
struct ShotEvent {
    let timestamp: Date
    let pixelBuffers: [CVPixelBuffer]
    let releaseFrameIndex: Int
    let impactFrameIndex: Int
    
    var releaseFrame: CVPixelBuffer? {
        guard releaseFrameIndex < pixelBuffers.count else { return nil }
        return pixelBuffers[releaseFrameIndex]
    }
    
    var impactFrame: CVPixelBuffer? {
        guard impactFrameIndex < pixelBuffers.count else { return nil }
        return pixelBuffers[impactFrameIndex]
    }
}