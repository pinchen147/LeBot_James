import Foundation
import UIKit
import AVFoundation

class GeminiLiveAPIClient: NSObject, ObservableObject {
    // MARK: - Properties
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession = URLSession.shared
    private let apiKey: String
    private var isConnected = false
    private var sessionHandle: String?
    
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    enum ConnectionStatus: Equatable {
        case disconnected
        case connecting
        case connected
        case error(String)
    }
    
    // MARK: - Initialization
    override init() {
        self.apiKey = AppConfig.getAPIKey()
        super.init()
        
        // Test API key validity
        if apiKey.isEmpty || apiKey.count < 20 {
            print("❌ Invalid API key - length: \(apiKey.count)")
        } else {
            print("✅ API key configured - length: \(apiKey.count)")
        }
    }
    
    // MARK: - Connection Management
    func connect() {
        guard !isConnected else { return }
        
        connectionStatus = .connecting
        
        // Construct WebSocket URL for Gemini Live API
        // Note: Live API might still be in limited preview
        var urlComponents = URLComponents()
        urlComponents.scheme = "wss"
        urlComponents.host = "generativelanguage.googleapis.com"
        urlComponents.path = "/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent"
        urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        
        guard let url = urlComponents.url else {
            connectionStatus = .error("Invalid URL")
            return
        }
        
        print("🔌 Connecting to Gemini Live API: \(url)")
        
        // Create WebSocket connection with proper configuration
        var request = URLRequest(url: url)
        request.setValue("websocket", forHTTPHeaderField: "Upgrade")
        request.setValue("Upgrade", forHTTPHeaderField: "Connection")
        
        webSocketTask = urlSession.webSocketTask(with: request)
        webSocketTask?.resume()
        
        // Start listening for messages
        listenForMessages()
        
        // Set a connection timeout
        DispatchQueue.global().asyncAfter(deadline: .now() + 10.0) {
            if self.connectionStatus == .connecting {
                print("❌ Connection timeout for Gemini Live API")
                self.connectionStatus = .error("Connection timeout")
                self.disconnect()
            }
        }
        
        // Wait a moment before sending setup to ensure connection is established
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
            if self.connectionStatus == .connecting {
                self.sendSetupMessage()
            }
        }
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
        connectionStatus = .disconnected
        print("🔌 Disconnected from Gemini Live API")
    }
    
    // MARK: - Message Handling
    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                // Continue listening
                self?.listenForMessages()
            case .failure(let error):
                print("❌ WebSocket receive error: \(error)")
                print("❌ Error code: \((error as NSError).code)")
                print("❌ Error domain: \((error as NSError).domain)")
                
                // Try to reconnect after a delay
                DispatchQueue.main.async {
                    self?.connectionStatus = .error(error.localizedDescription)
                }
                
                // Attempt reconnection after 3 seconds
                DispatchQueue.global().asyncAfter(deadline: .now() + 3.0) {
                    print("🔄 Attempting to reconnect...")
                    self?.reconnect()
                }
            }
        }
    }
    
    private func reconnect() {
        guard !isConnected else { return }
        disconnect()
        connect()
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            handleTextMessage(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                handleTextMessage(text)
            }
        @unknown default:
            break
        }
    }
    
    private func handleTextMessage(_ text: String) {
        print("📱 Received message: \(text)")
        
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        
        // Handle setup complete
        if json["setupComplete"] != nil {
            isConnected = true
            connectionStatus = .connected
            print("✅ Gemini Live API connected successfully")
            return
        }
        
        // Handle server content (AI response)
        if let serverContent = json["serverContent"] as? [String: Any] {
            handleServerContent(serverContent)
        }
        
        // Handle session resumption updates
        if let sessionUpdate = json["sessionResumptionUpdate"] as? [String: Any] {
            if let newHandle = sessionUpdate["newHandle"] as? String {
                sessionHandle = newHandle
            }
        }
        
        // Handle go away message
        if let goAway = json["goAway"] as? [String: Any] {
            print("⚠️ Server sending go away message")
            if let timeLeft = goAway["timeLeft"] as? String {
                print("Time left: \(timeLeft)")
            }
        }
    }
    
    private func handleServerContent(_ serverContent: [String: Any]) {
        // Handle model turn (text response)
        if let modelTurn = serverContent["modelTurn"] as? [String: Any],
           let parts = modelTurn["parts"] as? [[String: Any]] {
            
            for part in parts {
                if let text = part["text"] as? String {
                    print("🤖 AI Response: \(text)")
                    parseAIResponse(text)
                }
            }
        }
        
        // Handle audio response
        if serverContent["audio"] != nil {
            // Handle audio response from native audio models
            print("🔊 Received audio response")
        }
    }
    
    private func parseAIResponse(_ text: String) {
        // Try to parse JSON response
        if let data = text.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let outcome = json["outcome"] as? String,
           let tip = json["tip"] as? String {
            
            let shotOutcome: ShotOutcome = outcome.lowercased() == "make" ? .make : .miss
            let result = ShotAnalysisResult(outcome: shotOutcome, tip: tip)
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .shotAnalysisComplete,
                    object: result
                )
            }
        }
    }
    
    // MARK: - Sending Messages
    private func sendSetupMessage() {
        let setupMessage: [String: Any] = [
            "setup": [
                "model": "models/gemini-2.0-flash-exp",
                "generationConfig": [
                    "responseModalities": ["TEXT"],
                    "temperature": 0.7,
                    "maxOutputTokens": 200
                ],
                "systemInstruction": [
                    "role": "user",
                    "parts": [
                        [
                            "text": """
                            You are LeBot James, an AI basketball coach. Analyze basketball shots and provide feedback.
                            
                            For each shot image, determine:
                            1. Was it a make or miss? (look for ball going through hoop)
                            2. One specific coaching tip about shooting form
                            
                            Focus on: shooting elbow, follow-through, knee bend, balance, arc
                            
                            Respond in JSON format:
                            {"outcome": "make" or "miss", "tip": "your coaching tip"}
                            
                            Keep tips under 10 words, be encouraging and specific.
                            """
                        ]
                    ]
                ]
            ]
        ]
        
        sendMessage(setupMessage)
    }
    
    func analyzeShot(frame: CVPixelBuffer, lastTip: String, completion: @escaping (ShotAnalysisResult) -> Void) {
        guard isConnected else {
            print("⚠️ AI not connected, using fallback analysis")
            // Provide a random outcome for testing when offline
            let randomOutcome: ShotOutcome = Bool.random() ? .make : .miss
            completion(ShotAnalysisResult(outcome: randomOutcome, tip: "AI analysis unavailable - practice your form!"))
            return
        }
        
        // Convert frame to image and then to base64
        guard let image = imageFromPixelBuffer(frame),
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(ShotAnalysisResult(outcome: .miss, tip: "Unable to process frame"))
            return
        }
        
        let base64Image = imageData.base64EncodedString()
        
        // Store completion handler for this request
        // In a production app, you'd want to track request IDs
        currentAnalysisCompletion = completion
        
        // Create prompt with context about last tip
        let avoidRepetition = lastTip.isEmpty ? "" : " Don't repeat this previous tip: '\(lastTip)'"
        let prompt = "Analyze this basketball shot.\(avoidRepetition) Respond in JSON format with outcome and tip."
        
        let message: [String: Any] = [
            "clientContent": [
                "turns": [
                    [
                        "role": "user",
                        "parts": [
                            [
                                "text": prompt
                            ],
                            [
                                "inlineData": [
                                    "mimeType": "image/jpeg",
                                    "data": base64Image
                                ]
                            ]
                        ]
                    ]
                ],
                "turnComplete": true
            ]
        ]
        
        sendMessage(message)
    }
    
    private var currentAnalysisCompletion: ((ShotAnalysisResult) -> Void)?
    
    private func sendMessage(_ message: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: data, encoding: .utf8) else {
            print("❌ Failed to serialize message")
            return
        }
        
        let webSocketMessage = URLSessionWebSocketTask.Message.string(jsonString)
        webSocketTask?.send(webSocketMessage) { error in
            if let error = error {
                print("❌ Failed to send message: \(error)")
            }
        }
    }
    
    // MARK: - Utility Methods
    private func imageFromPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Notification Extension
extension NSNotification.Name {
    static let shotAnalysisComplete = NSNotification.Name("shotAnalysisComplete")
}