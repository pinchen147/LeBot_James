import Foundation
import ARKit
import AVFoundation

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
        
        // For now, connect directly with API key until ephemeral token service is deployed
        let apiKey = Config.getAPIKey()
        if !apiKey.isEmpty && apiKey != "YOUR_GEMINI_API_KEY_HERE" {
            print("🔑 Connecting to Live API with API key...")
            self.geminiLiveClient.connectWithAPIKey(apiKey)
        } else {
            print("❌ No valid API key found, using fallback REST API only")
        }
        
        // Later, when token service is deployed, uncomment this:
        /*
        authService.fetchEphemeralToken { [weak self] token in
            guard let self = self, let token = token else {
                print("❌ Failed to get ephemeral token, using fallback REST API")
                return
            }
            
            self.currentToken = token
            print("✅ Ephemeral token acquired, connecting to Live API...")
            
            // Connect to Gemini Live API
            self.geminiLiveClient.connect(with: token)
        }
        */
        
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
    
    func processFrame(_ pixelBuffer: CVPixelBuffer) {
        guard isSessionActive, !isAnalyzing else { return }
        
        // Pass frame to shot detector for processing
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // Create a local copy to avoid capture warnings
            let frameBuffer = pixelBuffer
            self?.shotDetector.processPixelBuffer(frameBuffer) { shotEvent in
                self?.handleShotEvent(shotEvent, frame: frameBuffer)
            }
        }
    }
    
    // MARK: - Private Methods
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
        
        // Send frame to Live API
        geminiLiveClient.sendFrame(imageData: imageData, lastTip: lastTipGiven)
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
