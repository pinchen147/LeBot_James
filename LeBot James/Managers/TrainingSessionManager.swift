import Foundation
import ARKit
import AVFoundation
import UIKit
import CoreMedia
import VideoToolbox

class TrainingSessionManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var makes: Int = 0
    @Published var totalShots: Int = 0
    @Published var isAnalyzing: Bool = false
    @Published var currentTip: String = ""
    
    // MARK: - Private Properties
    private let shotDetector = ShotEventDetector()
    private let frameSelector = SmartFrameSelector()
    private let authService = SessionAuthService()
    private let geminiLiveClient = GeminiLiveClient()
    private let aiAnalysisClient = AIAnalysisClient() // Fallback REST API
    private let coachingTipsManager = CoachingTipsManager()
    let responseRenderer = ResponseRenderer() // Made public for AR integration
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    // MARK: - 1 FPS Processing Properties
    private var lastAnalysisTime: TimeInterval = 0
    private let analysisInterval: TimeInterval = 1.0 // 1 FPS = 1 second interval
    private var pendingFrameForAnalysis: CMSampleBuffer?
    
    private var isSessionActive = false
    @Published var lastShotOutcome: ShotOutcome?
    private var lastTipGiven: String = ""
    private var currentToken: EphemeralToken?
    private var isLiveAPIAvailable = false
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupComponents()
    }
    
    // MARK: - Public Methods
    func startSession() {
        guard !isSessionActive else { return }
        
        isSessionActive = true
        makes = 0
        totalShots = 0
        isAnalyzing = false
        currentTip = ""
        lastTipGiven = ""
        
        print("🚀 Starting training session...")
        
        // Try ephemeral token first (production mode)
        fetchEphemeralToken { [weak self] token in
            guard let self = self else { return }
            
            if let token = token {
                print("🔑 Connecting to Live API with ephemeral token...")
                self.currentToken = token
                self.geminiLiveClient.connect(with: token)
            } else {
                print("⚠️ Failed to get ephemeral token, falling back to API key (development mode)")
                let apiKey = Config.getAPIKey()
                if !apiKey.isEmpty && apiKey != "YOUR_GEMINI_API_KEY_HERE" {
                    print("🔑 Connecting to Live API with API key...")
                    self.geminiLiveClient.connectWithAPIKey(apiKey)
                } else {
                    print("❌ No valid API key found, using fallback REST API only")
                }
            }
        }
        
        print("✅ Training session started")
    }
    
    func endSession() {
        guard isSessionActive else { return }
        
        isSessionActive = false
        speechSynthesizer.stopSpeaking(at: .immediate)
        
        // Disconnect from Live API
        geminiLiveClient.disconnect()
        currentToken = nil
        isLiveAPIAvailable = false
        
        print("Training session ended - Makes: \(makes)/\(totalShots)")
    }
    
    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard isSessionActive else { return }
        
        // Store the current frame for potential analysis
        self.pendingFrameForAnalysis = sampleBuffer
        
        // Check if it's time for AI analysis (1 FPS throttling)
        let currentTime = CACurrentMediaTime()
        if currentTime - lastAnalysisTime >= analysisInterval {
            lastAnalysisTime = currentTime
            processFrameForAIAnalysis(sampleBuffer)
        }
        
        // Continue with shot detection for immediate feedback (if not analyzing)
        if !isAnalyzing {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.shotDetector.processSampleBuffer(sampleBuffer) { shotEvent in
                    if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                        self?.handleShotEvent(shotEvent, frame: pixelBuffer)
                    }
                }
            }
        }
    }
    
    // MARK: - AI Analysis Processing (1 FPS)
    private func processFrameForAIAnalysis(_ sampleBuffer: CMSampleBuffer) {
        guard geminiLiveClient.isConnectedToAI else {
            print("⚠️ Not connected to AI - skipping analysis")
            return
        }
        
        // Convert CMSampleBuffer to UIImage for AI analysis
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let image = self?.convertSampleBufferToUIImage(sampleBuffer) else {
                print("❌ Failed to convert sample buffer to UIImage")
                return
            }
            
            DispatchQueue.main.async {
                self?.isAnalyzing = true
                print("🔍 Sending frame to AI for analysis (1 FPS)")
                self?.geminiLiveClient.sendFrame(image)
            }
        }
    }
    
    // MARK: - Private Methods
    private func fetchEphemeralToken(completion: @escaping (EphemeralToken?) -> Void) {
        authService.fetchEphemeralToken { token in
            if let token = token {
                print("✅ Ephemeral token received successfully!")
            } else {
                print("❌ Failed to receive ephemeral token")
            }
            completion(token)
        }
    }
    
    private func setupComponents() {
        // Configure speech synthesizer
        speechSynthesizer.delegate = self
        
        // Configure AI analysis client (fallback)
        aiAnalysisClient.configure()
        
        // Configure Gemini Live client
        geminiLiveClient.onConnectionChange = { [weak self] connected in
            DispatchQueue.main.async {
                self?.isLiveAPIAvailable = connected
                print(connected ? "✅ Live API connected" : "❌ Live API disconnected")
            }
        }
        
        // Configure AI response handling (new format)
        geminiLiveClient.onReceiveResponse = { [weak self] result in
            DispatchQueue.main.async {
                self?.isAnalyzing = false
                self?.handleAIAnalysisResult(result)
            }
        }
        
        // Keep backward compatibility
        geminiLiveClient.onReceiveAnalysis = { [weak self] result in
            DispatchQueue.main.async {
                self?.processAnalysisResult(result)
            }
        }
        
        print("✅ Training session components configured")
    }
    
    private func handleShotEvent(_ shotEvent: ShotEvent, frame: CVPixelBuffer) {
        guard isSessionActive else { return }
        
        DispatchQueue.main.async {
            self.isAnalyzing = true
        }
        
        // Select key frames for analysis
        frameSelector.selectFrames(from: shotEvent, currentFrame: frame) { [weak self] selectedFrames in
            self?.analyzeShot(frames: selectedFrames)
        }
    }
    
    private func analyzeShot(frames: [CVPixelBuffer]) {
        guard let frame = frames.first else {
            DispatchQueue.main.async {
                self.isAnalyzing = false
            }
            return
        }
        
        // Use Live API if available, otherwise fallback to REST API
        if isLiveAPIAvailable {
            print("🚀 Analyzing shot with Gemini Live API")
            sendFrameToLiveAPI(frame)
        } else {
            print("📡 Analyzing shot with Gemini REST API (fallback)")
            aiAnalysisClient.analyzeShot(frame: frame, lastTip: lastTipGiven) { [weak self] result in
                DispatchQueue.main.async {
                    self?.processAnalysisResult(result)
                }
            }
        }
    }
    
    private func sendFrameToLiveAPI(_ frame: CVPixelBuffer) {
        // Convert CVPixelBuffer to image data
        guard let image = imageFromPixelBuffer(frame),
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to convert frame to image data")
            // Fallback to REST API
            aiAnalysisClient.analyzeShot(frame: frame, lastTip: lastTipGiven) { [weak self] result in
                DispatchQueue.main.async {
                    self?.processAnalysisResult(result)
                }
            }
            return
        }
        
        // Send image with prompt for shot analysis
        geminiLiveClient.sendImageWithPrompt(imageData: imageData, lastTip: lastTipGiven)
    }
    
    private func imageFromPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func processAnalysisResult(_ result: ShotAnalysisResult) {
        isAnalyzing = false
        
        // Update shot counter
        totalShots += 1
        if result.outcome == .make {
            makes += 1
        }
        
        // Publish the outcome for the UI
        lastShotOutcome = result.outcome
        
        // Prepare feedback message
        let feedbackTip = result.tip.isEmpty ? coachingTipsManager.getContextualTip(for: result.outcome) : result.tip
        
        // Store the tip to avoid repetition
        lastTipGiven = feedbackTip
        currentTip = feedbackTip
        
        // Render visual feedback
        responseRenderer.renderShotResult(result.outcome)
        
        // Provide audio feedback
        provideFeedback(feedbackTip, outcome: result.outcome)
        
        print("Shot analyzed: \(result.outcome.rawValue) - \(feedbackTip)")
    }
    
    private func provideFeedback(_ tip: String, outcome: ShotOutcome) {
        // Create utterance with Michael Jordan-style confidence
        let utterance = AVSpeechUtterance(string: tip)
        
        // Configure voice settings based on outcome
        switch outcome {
        case .make:
            utterance.rate = AppConfig.Audio.speechRate
            utterance.pitchMultiplier = AppConfig.Audio.speechPitch + 0.1 // Slightly higher for makes
            utterance.volume = AppConfig.Audio.speechVolume
        case .miss:
            utterance.rate = AppConfig.Audio.speechRate - 0.1 // Slightly slower for misses
            utterance.pitchMultiplier = AppConfig.Audio.speechPitch
            utterance.volume = AppConfig.Audio.speechVolume
        }
        
        // Try to use a more authoritative voice if available
        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }
        
        // Set up audio session for better playback
        configureAudioSession()
        
        speechSynthesizer.speak(utterance)
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Audio session configuration error: \(error)")
        }
    }
    

}

// MARK: - AVSpeechSynthesizerDelegate
extension TrainingSessionManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("Finished speaking feedback")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("Started speaking feedback")
    }
}
