1.0 Technical Overview
1.1 Feature: LeBot_James: AI Basketball Coach (MVP)
1.2 PDD Reference: LeBot_James: AI Basketball Coach – Product Design Document (MVP)
1.3 Engineering Objective: To build a robust, performant, and testable native iOS application that provides real-time basketball shot counting and AI-driven form coaching. The system will use on-device computer vision to trigger analysis and a secure cloud backend proxy to interface with the Gemini AI model.
1.4 Key Technical Decisions:
Client Architecture: The core logic is implemented within a TrainingSessionManager for predictable and testable state management. This follows a clean architecture pattern with clear separation of concerns.
Shot Detection Strategy: The MVP uses VNDetectHumanBodyPoseRequest to detect basketball shooting motions by analyzing pose transitions from shooting stance to release. This provides reliable shot event detection with fallback simulation for testing.
API Integration: **UPDATED**: Direct integration with Google Gemini Live API via WebSocket connection for real-time, low-latency AI coaching. The API key is securely stored in the client for MVP simplicity, with future plans for serverless proxy architecture.
Visual Feedback: Rich SwiftUI overlays provide immediate visual feedback including make/miss indicators, shooting percentages, and coaching tips displayed directly over the camera feed.
Tech Stack: The app targets iOS 17+ leveraging latest Vision framework capabilities. Uses native URLSession for WebSocket connections to Gemini Live API, eliminating third-party networking dependencies.
Data & State: Zero user authentication for MVP. All session data is ephemeral. Coaching knowledge base is a bundled coaching_tips.json file with contextual tip selection based on shot outcomes.
Audio Feedback: Enhanced AVSpeechSynthesizer implementation with outcome-based voice modulation and proper audio session management for Michael Jordan-style coaching delivery.
2.0 Finalized Architecture & Tech Stack
2.1 System Architecture
Generated mermaid
graph TD
    subgraph "User's iPhone"
        A[iOS App: SwiftUI Views] -- Displays Camera Feed & Overlays --> U(User);
        A -- User Actions (Start/End Session) --> B[TrainingSessionManager];
        B -- Controls --> C[ARViewRepresentable AVCaptureSession];
        C -- Video Frames --> D[ShotEventDetector];
        D -- Uses --> E[Vision Framework: VNDetectHumanBodyPoseRequest];
        D -- Shot Detected Event --> B;
        B -- Triggers Analysis --> F[GeminiLiveAPIClient];
        F -- WebSocket Connection --> G[Google Gemini Live API];
        B -- Receives Response --> H[Response Processing];
        H -- Updates UI State --> A;
        H -- Triggers Audio --> I[Enhanced AVSpeechSynthesizer];
        K[CoachingTipsManager] -- Loads --> L[coaching_tips.json];
        K -- Provides Contextual Tips --> B;
    end

    subgraph "Cloud Services"
        G -- Real-time WebSocket --> M[Gemini 2.0 Flash Live Model];
        M -- JSON Response --> F;
    end

    style U fill:#fff,stroke:#333,stroke-width:2px
    style M fill:#f9f,stroke:#333,stroke-width:2px
Use code with caution.
Mermaid
2.2 Final Tech Stack
Category	Technology	Version	Rationale/Notes
Mobile Platform	iOS	17.0+	To use the latest, most performant SwiftUI & Vision APIs.
UI Framework	SwiftUI	5.0+	Native, modern, and declarative UI development for iOS.
Core Language	Swift	5.9+	
Dependencies	Swift Package Manager	-	Apple's standard for dependency management. No external dependencies for MVP.
Networking	Native URLSession	-	**UPDATED**: WebSocket connections to Gemini Live API using native URLSession for real-time communication.
On-Device Vision	Apple Vision Framework	-	Native, high-performance framework. Advanced pose analysis with VNDetectHumanBodyPoseRequest.
Audio	AVFoundation	-	Enhanced AVSpeechSynthesizer with outcome-based voice modulation and audio session management.
AI Model	**UPDATED**: Google Gemini Live API	gemini-2.0-flash-exp	Real-time multimodal AI with WebSocket support for low-latency coaching feedback.
Camera Integration	AVCaptureSession	-	Direct camera integration with proper permissions handling and background processing.
Configuration	Config Management	-	Centralized app configuration with secure API key storage and environment-specific settings.
CI/CD	GitHub Actions	-	For automated linting, testing, and building on PRs and merges.
Linting	SwiftLint	0.54+	To enforce consistent code style and best practices.
2.3 Directory Structure
Generated plaintext
LeBot James/
├── LeBot_JamesApp.swift           # App entry point
├── ContentView.swift              # Root view controller
├── Assets.xcassets/               # Images, icons, etc.
├── Info.plist                     # App configuration and permissions
├── Configuration/
│   ├── Config.swift              # Centralized configuration management
│   └── AppConfig.swift           # Configuration access layer
├── Resources/
│   └── coaching_tips.json        # Comprehensive coaching knowledge base with contextual tips
├── Managers/
│   ├── TrainingSessionManager.swift    # Core session orchestration with state management
│   ├── ShotEventDetector.swift        # Advanced Vision-based shot detection with pose analysis
│   ├── SmartFrameSelector.swift       # Intelligent frame selection for optimal AI analysis
│   ├── GeminiLiveAPIClient.swift      # **NEW**: Real-time WebSocket client for Gemini Live API
│   ├── CoachingTipsManager.swift      # **NEW**: Contextual coaching tips management
│   ├── ResponseRenderer.swift          # Visual feedback rendering
│   └── AIAnalysisClient.swift         # Legacy analysis client (replaced by Live API)
├── Views/
│   ├── LoginView.swift                # Entry/onboarding screen
│   ├── CameraTrainingView.swift       # **ENHANCED**: Main training interface with rich overlays
│   └── ARViewRepresentable.swift      # **ENHANCED**: Camera integration with proper permissions
└── Tests/
    ├── LeBot JamesTests/              # Unit tests
    └── LeBot JamesUITests/            # E2E tests
Use code with caution.
3.0 Data Model & API Contract
3.1 Local Data
No database schema is required for the MVP. The coaching knowledge base is an enhanced local JSON file with contextual tip categories.
coaching_tips.json Format:
Generated json
{
  "tips": [
    "Excellent follow-through on that shot!",
    "Try to keep your elbow tucked in closer to your body.",
    "Bend your knees more to get power from your legs.",
    "Hold your follow-through until the ball hits the rim.",
    "Focus on a consistent shooting arc.",
    "Keep your shooting hand directly under the ball."
  ],
  "encouragement": [
    "Great shot mechanics!",
    "Nice improvement!",
    "Keep that form consistent!"
  ],
  "makes": [
    "Money! Great shot!",
    "Nothing but net!",
    "Swish! Perfect form!"
  ],
  "misses": [
    "Keep shooting with confidence!",
    "Good form, just keep practicing!",
    "Almost there, stay focused!"
  ]
}
Use code with caution.
Json
3.2 API Integration Specifications
**UPDATED**: The iOS client now connects directly to Google Gemini Live API via WebSocket for real-time communication.

WebSocket Endpoint: wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent

Authentication: Direct API key authentication with query parameter
Connection Flow:
1. Establish WebSocket connection with API key
2. Send setup message with model configuration (gemini-2.0-flash-exp)
3. Exchange real-time messages for shot analysis
4. Handle session management and reconnection

Message Format:
Setup Message:
```json
{
  "setup": {
    "model": "models/gemini-2.0-flash-exp",
    "generationConfig": {
      "responseModalities": ["TEXT"],
      "temperature": 0.7,
      "maxOutputTokens": 200
    },
    "systemInstruction": "You are LeBot James, an AI basketball coach..."
  }
}
```

Analysis Request:
```json
{
  "clientContent": {
    "turns": [{
      "role": "user",
      "parts": [
        {"text": "Analyze this basketball shot..."},
        {"inlineData": {"mimeType": "image/jpeg", "data": "base64_image"}}
      ]
    }],
    "turnComplete": true
  }
}
```

Response Format:
```json
{
  "outcome": "make" | "miss",
  "tip": "coaching tip string"
}
```
Use code with caution.
Json
This will be decoded into a Swift struct:
Generated swift
struct ShotAnalysisResponse: Codable {
    let outcome: ShotOutcome
    let tip: String?

    enum ShotOutcome: String, Codable {
        case MAKE, MISS, INDETERMINATE
    }
}
Use code with caution.
Swift
Error Responses:
400 Bad Request: Missing image data or invalid request format.
401 Unauthorized: Invalid or missing App Check token.
500 Internal Server Error: An unexpected error occurred within the cloud function.
503 Service Unavailable: The Gemini API is unreachable or returned an error.
4.0 Component & Logic Breakdown
4.1 Backend Component Responsibilities
Module	Responsibility	Key Dependencies
analyzeShot (Cloud Function)	Acts as a secure proxy. Validates the request, injects the GEMINI_API_KEY, constructs the prompt for Gemini, calls the Gemini API, parses the response, and forwards a clean JSON object to the client.	firebase-functions, Google AI SDK
4.2 iOS Component Responsibilities
Component/Module	Responsibility	Props/Key Dependencies
TrainingSessionManager.swift	**UPDATED**: Core session orchestrator managing state, camera, vision, and AI services. Handles shot counting, feedback coordination, and audio session management.	ShotEventDetector, GeminiLiveAPIClient, CoachingTipsManager, AVSpeechSynthesizer
CameraTrainingView.swift	**ENHANCED**: Main training interface with rich visual overlays, real-time shot counters, and contextual feedback display. Includes enhanced animations and color-coded performance indicators.	@StateObject TrainingSessionManager
ShotEventDetector.swift	**ENHANCED**: Advanced pose-based shot detection using VNDetectHumanBodyPoseRequest. Analyzes shooting motion transitions from stance to release with fallback simulation.	Vision framework
GeminiLiveAPIClient.swift	**NEW**: Real-time WebSocket client for Gemini Live API. Manages connection state, message handling, session resumption, and error recovery.	URLSession WebSocket
CoachingTipsManager.swift	**NEW**: Contextual coaching tips management with outcome-based tip selection. Loads and manages categorized coaching knowledge base.	coaching_tips.json
ARViewRepresentable.swift	**ENHANCED**: Camera integration with proper permissions handling, session configuration, and frame processing delegation.	AVCaptureSession, TrainingSessionManager
ResponseRenderer.swift	Visual feedback rendering for shot outcomes and coaching tips.	ShotOutcome
5.0 Implementation Plan: A Step-by-Step Checklist
Phase 0: Setup & Scaffolding
Initialize Xcode project with the defined directory structure.
Set up GitHub repository with a main branch and protection rules.
Integrate Swift Package Manager and add Alamofire.
Set up SwiftLint with a default .swiftlint.yml configuration.
Set up Firebase project, create a Cloud Function for the analyzeShot proxy, and enable App Check.
Create basic GitHub Actions workflow for linting and running empty tests.
Phase 1: Backend & Core Services (Headless First)
Implement the analyzeShot cloud function to securely call the Gemini API. Test it via curl or Postman.
Implement GeminiService.swift and ShotAnalysisResponse.swift.
Write unit tests for GeminiService to mock network responses (success and failure cases).
Implement AudioFeedbackPlayer.swift and write unit tests to verify it attempts to speak.
Create the coaching_tips.json file and a simple parser to load it into memory.
Phase 2: On-Device Vision & Logic
Build CameraManager.swift to configure and run an AVCaptureSession.
Implement the CameraView representable to display the camera's preview layer.
Implement the initial ShotDetector.swift, focusing on VNDetectHumanBodyPoseRequest to identify a "shooting stance" and arm release motion.
Implement the TrainingSessionViewModel as a state machine.
Wire a mocked ShotDetector (e.g., triggered by a screen tap) to the ViewModel to test the state flow: detecting -> analyzing -> feedback.
Phase 3: UI & Full Integration
Build the static UI overlays: ShotCountView, FeedbackOverlayView.
Connect the UI overlays to the TrainingSessionViewModel's published properties.
Replace the mocked ShotDetector with the real implementation that processes live camera frames.
Implement the simple OnboardingView with a button to navigate to the TrainingSessionView.
Perform manual end-to-end testing in various lighting conditions.
(Post-MVP Refinement): Augment ShotDetector with VNDetectTrajectoriesRequest to improve the make/miss outcome accuracy.
6.0 Testing Strategy
6.1 Unit Tests (XCTest):
Target: TrainingSessionViewModel, GeminiService, ShotDetector (with mock CVImageBuffer data), and all utility classes.
Goal: Verify business logic in isolation. Test all states of the FSM. Mock all external dependencies. Target >90% code coverage.
6.2 Integration Tests (XCTest):
Target: The flow from TrainingSessionViewModel through GeminiService.
Goal: Verify that the ViewModel correctly initiates a network call and processes the mocked successful or error response from the service layer.
6.3 End-to-End (E2E) Tests (XCUITest):
Target: Key user flows.
Flow 1 (Happy Path): Launch App -> Tap "Start Session" -> Verify Camera View is active -> Use launch arguments to mock a shot event -> Verify counter increments and feedback overlay appears.
Goal: Ensure the integrated app behaves as expected from the user's perspective.
7.0 Deployment & DevOps
7.1 Environment Variables
Firebase Cloud Function: GEMINI_API_KEY (set in the Google Cloud Secret Manager).
iOS App: API_PROXY_URL (stored in the app's .plist file, using different plists for Debug/Release builds).
7.2 Build Process
Local builds via Xcode (Cmd+R, Cmd+B).
CI builds via xcodebuild build-for-testing ... and xcodebuild test ... commands.
7.3 CI/CD Pipeline (GitHub Actions)
On Pull Request:
Lint: Run swiftlint.
Test: Run all XCTest unit and integration tests.
Build: Ensure the app compiles for release.
On Merge to main:
All PR steps pass.
(Manual Trigger) Deploy: A workflow builds, archives, and uploads the app to TestFlight for internal testing.