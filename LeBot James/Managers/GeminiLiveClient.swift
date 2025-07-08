import Foundation

class GeminiLiveClient: NSObject, URLSessionWebSocketDelegate {
    // MARK: - Properties
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private let geminiLiveURL = "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent"
    
    // Callback handlers
    var onConnectionChange: ((Bool) -> Void)?
    var onReceiveMessage: ((String) -> Void)?
    var onReceiveAnalysis: ((ShotAnalysisResult) -> Void)?
    
    // Connection state
    private var isConnected = false
    private var isSessionConfigured = false
    private var currentToken: EphemeralToken?
    private var apiKey: String?
    
    // MARK: - Public Methods
    func connect(with ephemeralToken: EphemeralToken) {
        print("🔌 Connecting to Gemini Live API with ephemeral token...")
        
        // Validate token
        guard ephemeralToken.isValid && ephemeralToken.canStartSession else {
            print("❌ Token is expired or cannot start session")
            onConnectionChange?(false)
            return
        }
        
        self.currentToken = ephemeralToken
        self.apiKey = nil
        
        connectToWebSocket(token: ephemeralToken.token, isEphemeral: true)
    }
    
    func connectWithAPIKey(_ apiKey: String) {
        print("🔌 Connecting to Gemini Live API with API key...")
        
        self.apiKey = apiKey
        self.currentToken = nil
        
        connectToWebSocket(token: apiKey, isEphemeral: false)
    }
    
    private func connectToWebSocket(token: String, isEphemeral: Bool) {
        // Use clean URL without query parameters
        guard let url = URL(string: geminiLiveURL) else {
            print("❌ Invalid Gemini Live URL")
            onConnectionChange?(false)
            return
        }
        
        var request = URLRequest(url: url)
        
        // **CRITICAL FIX**: Use Authorization header instead of query parameter
        if isEphemeral {
            // For ephemeral tokens, use "Token" scheme in Authorization header
            request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
            print("🔑 Using ephemeral token in Authorization header")
        } else {
            // For API keys, use query parameter (development only)
            guard let urlWithKey = URL(string: "\(geminiLiveURL)?key=\(token)") else {
                print("❌ Invalid Gemini Live URL with API key")
                onConnectionChange?(false)
                return
            }
            request = URLRequest(url: urlWithKey)
            print("🔑 Using API key in query parameter (development mode)")
        }
        
        // Create URL session with delegate
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Config.API.requestTimeout
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
        
        // Create WebSocket task
        webSocketTask = urlSession?.webSocketTask(with: request)
        webSocketTask?.resume()
        
        // Start receiving messages
        receiveMessage()
        
        print("🚀 WebSocket connection initiated")
    }
    
    func disconnect() {
        print("🔌 Disconnecting from Gemini Live API")
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        urlSession?.invalidateAndCancel()
        urlSession = nil
        isConnected = false
        isSessionConfigured = false
        currentToken = nil
        apiKey = nil
        onConnectionChange?(false)
    }
    
    func sendVideoFrame(imageData: Data, lastTip: String = "") {
        guard isConnected && isSessionConfigured else {
            print("❌ Not connected or session not configured")
            return
        }
        
        let base64String = imageData.base64EncodedString()
        
        // Send video frame as realtime input
        let frameMessage: [String: Any] = [
            "realtimeInput": [
                "video": [
                    "mimeType": "image/jpeg",
                    "data": base64String
                ]
            ]
        ]
        
        sendMessage(frameMessage)
    }
    
    func sendImageWithPrompt(imageData: Data, lastTip: String = "") {
        guard isConnected && isSessionConfigured else {
            print("❌ Not connected or session not configured")
            return
        }
        
        let base64String = imageData.base64EncodedString()
        
        // Send image with text prompt using clientContent
        let message: [String: Any] = [
            "clientContent": [
                "turns": [
                    [
                        "role": "user",
                        "parts": [
                            [
                                "text": createAnalysisPrompt(lastTip: lastTip)
                            ],
                            [
                                "inlineData": [
                                    "mimeType": "image/jpeg",
                                    "data": base64String
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
    
    private func sendMessage(_ message: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: message)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            
            let webSocketMessage = URLSessionWebSocketTask.Message.string(jsonString)
            webSocketTask?.send(webSocketMessage) { error in
                if let error = error {
                    print("❌ WebSocket sending error: \(error)")
                } else {
                    print("📡 Message sent to Gemini Live API")
                }
            }
        } catch {
            print("❌ Error creating message: \(error)")
        }
    }
    
    // MARK: - Private Methods
    private func configureSession() {
        print("⚙️ Configuring Gemini Live session...")
        
        // Initial setup message for Live API with Gemini 2.0 Flash
        let setupMessage: [String: Any] = [
            "setup": [
                "model": "models/gemini-2.0-flash-live-001",
                "generationConfig": [
                    "candidateCount": 1,
                    "temperature": 0.7,
                    "topP": 0.95,
                    "topK": 40,
                    "maxOutputTokens": 200,
                    "responseModalities": ["TEXT"],
                    "mediaResolution": "MEDIA_RESOLUTION_LOW"  // For better performance
                ],
                "systemInstruction": [
                    "parts": [
                        [
                            "text": """
                            You are LeBot James, an AI basketball coach. Analyze basketball shot videos and provide real-time feedback.
                            
                            For each shot, determine:
                            1. Whether it was a make or miss
                            2. Provide a specific, actionable coaching tip
                            
                            Return your response as valid JSON in this exact format:
                            {
                                "outcome": "make" or "miss",
                                "tip": "Your specific coaching tip here (max 10 words)"
                            }
                            
                            Focus on: shooting form, elbow alignment, follow-through, arc, balance.
                            Be encouraging and specific.
                            """
                        ]
                    ]
                ],
                "tools": []  // Can add tools here if needed
            ]
        ]
        
        sendMessage(setupMessage)
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(.string(let text)):
                self?.handleReceivedMessage(text)
                self?.onReceiveMessage?(text)
                self?.receiveMessage() // Listen for next message
                
            case .success(.data(let data)):
                if let text = String(data: data, encoding: .utf8) {
                    self?.handleReceivedMessage(text)
                    self?.onReceiveMessage?(text)
                }
                self?.receiveMessage()
                
            case .failure(let error):
                print("❌ WebSocket receive error: \(error)")
                self?.handleConnectionError(error)
                
            @unknown default:
                print("❌ Unknown WebSocket message type")
                self?.receiveMessage()
            }
        }
    }
    
    private func handleConnectionError(_ error: Error) {
        // Check if it's a specific error we can handle
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                print("❌ No internet connection")
            case .networkConnectionLost:
                print("❌ Network connection lost")
            case .timedOut:
                print("❌ Connection timed out")
            default:
                print("❌ Connection error: \(urlError.localizedDescription)")
            }
        }
        
        self.isConnected = false
        self.isSessionConfigured = false
        self.onConnectionChange?(false)
    }
    
    private func handleReceivedMessage(_ message: String) {
        // Parse the Live API message
        if let data = message.data(using: .utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                // Debug print
                print("📨 Received message type: \(json?.keys.joined(separator: ", ") ?? "unknown")")
                
                // Check for setup complete message
                if json?["setupComplete"] != nil {
                    print("✅ Session setup complete")
                    self.isSessionConfigured = true
                    return
                }
                
                // Check for server content
                if let serverContent = json?["serverContent"] as? [String: Any] {
                    handleServerContent(serverContent)
                }
                
                // Check for go away message
                if let goAway = json?["goAway"] as? [String: Any],
                   let timeLeft = goAway["timeLeft"] as? [String: Any] {
                    let seconds = timeLeft["seconds"] as? Int ?? 0
                    print("⚠️ Server will disconnect in: \(seconds) seconds")
                }
                
                // Check for errors
                if let error = json?["error"] as? [String: Any] {
                    let code = error["code"] as? String ?? "unknown"
                    let message = error["message"] as? String ?? "Unknown error"
                    print("❌ Server error: \(code) - \(message)")
                }
                
            } catch {
                print("❌ Error parsing message: \(error)")
            }
        }
    }
    
    private func handleServerContent(_ serverContent: [String: Any]) {
        // Check if generation is complete
        if let generationComplete = serverContent["generationComplete"] as? Bool,
           generationComplete {
            print("✅ Generation complete")
        }
        
        // Extract model turn content
        if let modelTurn = serverContent["modelTurn"] as? [String: Any],
           let parts = modelTurn["parts"] as? [[String: Any]] {
            
            for part in parts {
                if let text = part["text"] as? String {
                    print("📝 Model response: \(text)")
                    // Try to parse as JSON response
                    parseAnalysisResponse(text)
                }
            }
        }
    }
    
    private func parseAnalysisResponse(_ text: String) {
        do {
            if let data = text.data(using: .utf8),
               let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let outcomeString = json["outcome"] as? String,
               let tip = json["tip"] as? String {
                
                let outcome: ShotOutcome = outcomeString.lowercased() == "make" ? .make : .miss
                let result = ShotAnalysisResult(outcome: outcome, tip: tip)
                
                DispatchQueue.main.async {
                    self.onReceiveAnalysis?(result)
                }
            }
        } catch {
            // If not JSON, it might be regular text
            print("📝 Non-JSON response: \(text)")
        }
    }
    
    private func createAnalysisPrompt(lastTip: String) -> String {
        let basePrompt = """
        Analyze this basketball shot and provide:
        1. Outcome: make or miss
        2. One specific coaching tip (max 10 words)
        
        Focus on: form, elbow alignment, follow-through, arc, balance.
        """
        
        let avoidRepetition = lastTip.isEmpty ? "" : " Don't repeat: '\(lastTip)'"
        
        return basePrompt + avoidRepetition
    }
    
    // MARK: - URLSessionWebSocketDelegate
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("✅ Direct WebSocket connection to Gemini Live API established")
        isConnected = true
        onConnectionChange?(true)
        
        // Configure the session after connection
        configureSession()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("❌ WebSocket connection closed with code: \(closeCode.rawValue)")
        if let reason = reason, let reasonString = String(data: reason, encoding: .utf8) {
            print("❌ Close reason: \(reasonString)")
        }
        isConnected = false
        isSessionConfigured = false
        onConnectionChange?(false)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("❌ WebSocket task completed with error: \(error)")
            handleConnectionError(error)
        }
    }
} 