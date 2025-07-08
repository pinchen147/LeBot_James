import SwiftUI
import AVFoundation

// Renamed to CameraPreviewView in spirit, but keeping the file name for now
// to avoid breaking other parts of the code. This does not use ARKit.
struct ARViewRepresentable: UIViewRepresentable {
    let sessionManager: TrainingSessionManager

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        // Setup orientation change notification
        NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            context.coordinator.handleOrientationChange(view: view)
        }
        
        // Check current camera permission status
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch authStatus {
        case .authorized:
            // Already authorized, set up camera immediately
            setupCamera(coordinator: context.coordinator, view: view)
        case .notDetermined:
            // Request permission
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.setupCamera(coordinator: context.coordinator, view: view)
                    } else {
                        print("❌ Camera access denied")
                        self.showPermissionAlert(on: view)
                    }
                }
            }
        case .denied, .restricted:
            print("❌ Camera access denied or restricted")
            showPermissionAlert(on: view)
        @unknown default:
            print("❌ Unknown camera authorization status")
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update preview layer frame when view bounds change
        DispatchQueue.main.async {
            if let previewLayer = uiView.layer.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) as? AVCaptureVideoPreviewLayer {
                // Always update frame to match the view bounds
                previewLayer.frame = uiView.bounds
                
                // Update video orientation based on current device orientation
                if let connection = previewLayer.connection {
                    if connection.isVideoOrientationSupported {
                        context.coordinator.getCurrentVideoOrientation { orientation in
                            connection.videoOrientation = orientation
                            print("📱 Updated video orientation to: \(orientation)")
                        }
                    }
                }
                
                // Force layout update
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                previewLayer.frame = uiView.bounds
                CATransaction.commit()
                
                print("📐 Updated preview layer frame: \(uiView.bounds)")
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(sessionManager: sessionManager)
    }
    
    // Helper function to set up camera with preview layer
    private func setupCamera(coordinator: Coordinator, view: UIView) {
        print("📸 Setting up camera...")
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Setup the capture session
            let success = coordinator.setupCaptureSession()
            
            guard success else {
                print("❌ Failed to setup capture session")
                return
            }
            
            DispatchQueue.main.async {
                // Create and configure the preview layer
                let previewLayer = AVCaptureVideoPreviewLayer(session: coordinator.captureSession)
                previewLayer.frame = view.bounds
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.backgroundColor = UIColor.clear.cgColor
                
                // Remove any existing preview layers
                view.layer.sublayers?.removeAll { $0 is AVCaptureVideoPreviewLayer }
                
                // Add the new preview layer
                view.layer.insertSublayer(previewLayer, at: 0)
                
                print("📐 Preview layer added with frame: \(view.bounds)")
                
                // Set the correct orientation for the preview layer
                if let connection = previewLayer.connection {
                    if connection.isVideoOrientationSupported {
                        coordinator.getCurrentVideoOrientation { orientation in
                            connection.videoOrientation = orientation
                            print("📱 Preview layer orientation set to: \(orientation)")
                        }
                    }
                }
                
                // Start the capture session
                DispatchQueue.global(qos: .userInitiated).async {
                    if !coordinator.captureSession.isRunning {
                        coordinator.captureSession.startRunning()
                        DispatchQueue.main.async {
                            print("✅ Camera session started successfully")
                            // Force a layout update
                            view.setNeedsLayout()
                            view.layoutIfNeeded()
                        }
                    } else {
                        print("✅ Camera session already running")
                    }
                }
            }
        }
    }
    
    private func showPermissionAlert(on view: UIView) {
        DispatchQueue.main.async {
            let label = UILabel()
            label.text = "Camera permission required.\nPlease enable in Settings."
            label.textColor = .white
            label.textAlignment = .center
            label.numberOfLines = 0
            label.translatesAutoresizingMaskIntoConstraints = false
            
            view.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
            ])
        }
    }

    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        let captureSession = AVCaptureSession()
        private let sessionManager: TrainingSessionManager
        private let sessionQueue = DispatchQueue(label: "com.lebotjames.sessionQueue")

        init(sessionManager: TrainingSessionManager) {
            self.sessionManager = sessionManager
            super.init()
        }

        func setupCaptureSession() -> Bool {
            var success = false
            
            sessionQueue.sync {
                captureSession.beginConfiguration()
                
                // Configure the session for high-quality video
                if captureSession.canSetSessionPreset(.hd1280x720) {
                    captureSession.sessionPreset = .hd1280x720
                } else if captureSession.canSetSessionPreset(.high) {
                    captureSession.sessionPreset = .high
                } else {
                    captureSession.sessionPreset = .medium
                }
                
                print("📱 Session preset: \(captureSession.sessionPreset)")
                
                // Find the back camera
                guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                    print("❌ Unable to find back camera")
                    captureSession.commitConfiguration()
                    return
                }
                
                print("📷 Found camera device: \(videoDevice.localizedName)")
                
                // Remove existing inputs
                captureSession.inputs.forEach { captureSession.removeInput($0) }
                
                // Create an input from the device
                do {
                    let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                    if captureSession.canAddInput(videoInput) {
                        captureSession.addInput(videoInput)
                        print("✅ Video input added successfully")
                    } else {
                        print("❌ Cannot add video input")
                        captureSession.commitConfiguration()
                        return
                    }
                } catch {
                    print("❌ Error creating video device input: \(error)")
                    captureSession.commitConfiguration()
                    return
                }
                
                // Remove existing outputs
                captureSession.outputs.forEach { captureSession.removeOutput($0) }
                
                // Create a video data output to get frames
                let videoOutput = AVCaptureVideoDataOutput()
                videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
                videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue", qos: .userInitiated))
                videoOutput.alwaysDiscardsLateVideoFrames = true
                
                if captureSession.canAddOutput(videoOutput) {
                    captureSession.addOutput(videoOutput)
                    print("✅ Video output added successfully")
                } else {
                    print("❌ Cannot add video output")
                    captureSession.commitConfiguration()
                    return
                }
                
                // Configure connection
                if let connection = videoOutput.connection(with: .video) {
                    if connection.isVideoOrientationSupported {
                        // Set default orientation - will be updated on main thread later
                        connection.videoOrientation = .portrait
                    }
                    print("📹 Video connection configured")
                }
                
                captureSession.commitConfiguration()
                print("✅ Capture session configured successfully")
                success = true
            }
            
            return success
        }

        // This delegate method is called for each frame from the camera
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            // Pass the complete sample buffer to preserve timestamp information
            sessionManager.processFrame(sampleBuffer)
        }
        
        // Helper method to get current video orientation (thread-safe)
        func getCurrentVideoOrientation(completion: @escaping (AVCaptureVideoOrientation) -> Void) {
            DispatchQueue.main.async {
                // Get the interface orientation for more reliable orientation detection
                let interfaceOrientation = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first?
                    .interfaceOrientation ?? .portrait
                
                let orientation: AVCaptureVideoOrientation
                switch interfaceOrientation {
                case .landscapeLeft:
                    orientation = .landscapeLeft
                case .landscapeRight:
                    orientation = .landscapeRight
                case .portraitUpsideDown:
                    orientation = .portraitUpsideDown
                default:
                    orientation = .portrait
                }
                
                completion(orientation)
            }
        }
        
        // Handle orientation changes
        func handleOrientationChange(view: UIView) {
            DispatchQueue.main.async {
                if let previewLayer = view.layer.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) as? AVCaptureVideoPreviewLayer {
                    // Update frame to match view bounds
                    previewLayer.frame = view.bounds
                    
                    // Update video orientation
                    if let connection = previewLayer.connection {
                        if connection.isVideoOrientationSupported {
                            self.getCurrentVideoOrientation { orientation in
                                connection.videoOrientation = orientation
                                print("🔄 Orientation changed to: \(orientation)")
                            }
                        }
                    }
                }
            }
        }
    }
}
