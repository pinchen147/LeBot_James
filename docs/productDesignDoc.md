# LeBot_James: AI Basketball Coach – Product Design Document (Production)
## 1. Overview

Solo basketball practice is a fundamental part of player development, but it often lacks a critical component: immediate, expert feedback. Players can shoot for hours, unknowingly reinforcing bad habits in their form. LeBot_James is an iOS-based AI basketball coach that watches you practice, providing the real-time analysis and feedback of a personal trainer, right on your iPhone.

The app uses the phone's camera, positioned on a tripod, to observe the player. By intelligently detecting shooting motions through advanced pose analysis and analyzing frames at 1 FPS with Google's Gemini 2.0 Flash via Live API, it provides real-time shot counting and personalized, actionable coaching tips delivered via enhanced audio feedback and rich visual overlays. The system analyzes shooting form, shot classification, and provides structured feedback with "The GOAT" persona - embodying the spirit of Michael Jordan and LeBron James.

This production-ready app is iOS-first, built for performance and reliability. The system is hyper-focused on two core functions: automatic shot counting and real-time AI coaching to perfect your form. ### The system design emphasizes:

**Hands-Free Operation**: Set up your phone on a tripod, start the session, and practice without interruption.

**1 FPS AI Analysis**: Intelligent frame throttling sends one optimal frame per second to Gemini 2.0 Flash for analysis, balancing real-time feedback with API efficiency.

**The GOAT Coaching Persona**: AI feedback embodies the intensity and wisdom of basketball legends, providing both positive reinforcement and corrective critique.

**Thread-Safe Architecture**: Proper main/background thread separation ensures smooth UI updates while processing camera frames and AI responses.

**Rich Visual Feedback**: SwiftUI overlays provide instant visual confirmation with enhanced animations, color-coded shooting percentages, and full-screen landscape support.

**Secure Authentication**: Production-ready ephemeral token system with backend proxy ensures secure API access without exposing credentials.

**Minimalist Interface**: The app consists of only two primary screens: a simple entry screen and the main camera view where all the action happens.

LeBot_James is the ultimate practice partner, using cutting-edge AI to make every training session more productive through immediate, expert-level feedback.

## 2. Feature Overview (Production)

The production system delivers a sophisticated feedback loop with two perfected core features.

| Feature | Description | Implementation Details |
|---------|-------------|------------------------|
| **1. Automatic Shot Counting** | The app detects each shot attempt through advanced computer vision and provides structured AI analysis with visual feedback. | **Vision Framework**: Uses VNDetectTrajectoriesRequest with CMSampleBuffer for proper timestamp preservation. **1 FPS Processing**: Intelligent throttling sends frames to AI once per second. **Rich UI**: Displays makes/total with color-coded percentages and professional animations. |
| **2. Real-Time AI Coaching** | "The GOAT" AI persona provides structured feedback with positive reinforcement and corrective critique after analyzing each shot. | **Gemini 2.0 Flash Integration**: WebSocket connection for sub-second responses with structured JSON output. **The GOAT Prompt**: Comprehensive system prompt creating Michael Jordan/LeBron James coaching persona. **Structured Response**: JSON format with shotID, outcome, shotType, and dual feedback structure. |
## 3. System Architecture

### Production Architecture with Threading Model

```
iPhone (Client App)
├─ Camera Integration              - AVCaptureSession with thread-safe implementation
├─ Training Session Manager        - Core orchestrator with 1 FPS throttling
│   ├─ Shot Event Detector         - VNDetectTrajectoriesRequest with CMSampleBuffer
│   ├─ Image Conversion Utils      - Thread-safe CMSampleBuffer → UIImage conversion
│   ├─ Gemini Live Client          - WebSocket client with structured response handling
│   ├─ Session Auth Service        - Ephemeral token authentication
│   └─ Coaching Prompts            - The GOAT system prompt configuration
├─ Threading Architecture
│   ├─ Main Thread                 - UI updates, user interactions
│   ├─ Camera Queue                - AVCaptureSession processing
│   ├─ Vision Queue                - Computer vision analysis
│   └─ Network Queue               - WebSocket communication
└─ Rich UI Layer (SwiftUI)         - Full landscape support with proper orientation handling

Cloud Services
├─ Google Gemini Live API          - WebSocket (gemini-2.0-flash-exp)
│   ├─ 1 FPS image analysis
│   ├─ Structured JSON responses
│   └─ The GOAT coaching persona
└─ Backend Proxy Server            - Node.js ephemeral token service
    ├─ Token generation & validation
    ├─ Rate limiting
    └─ Security layer
```

### Key Architectural Features:
- **Thread-Safe Design**: Proper separation of UI, camera, vision, and network operations
- **1 FPS Processing**: Intelligent frame throttling for efficient API usage
- **Structured AI Responses**: JSON format with comprehensive coaching feedback
- **Secure Authentication**: Production-ready ephemeral token system
- **The GOAT Persona**: Sophisticated prompt engineering for expert-level coaching

### Typical Session Flow:

1. **Authentication**: App requests ephemeral token from backend proxy server

2. **Session Setup**: WebSocket connection established with Gemini Live API using token

3. **Camera Initialization**: AVCaptureSession starts on background thread with proper permissions

4. **1 FPS Monitoring**: TrainingSessionManager processes frames at 1 FPS while maintaining continuous shot detection

5. **Shot Detection**: VNDetectTrajectoriesRequest analyzes CMSampleBuffer preserving timestamps

6. **AI Analysis**: When 1-second interval passes, current frame converted to UIImage and sent to Gemini

7. **The GOAT Response**: Gemini 2.0 Flash returns structured JSON:
   ```json
   {
     "shotID": "2024-01-15T14:30:22.123Z",
     "outcome": "MAKE",
     "shotType": "Mid-Range",
     "analysis": {
       "positiveFeedback": "Excellent form! Your elbow was perfectly aligned.",
       "correctiveFeedback": "Plant those feet wider for better balance."
     }
   }
   ```

8. **Feedback Delivery**:
   - **Visual**: Shot outcome overlay with animations
   - **Audio**: Combined positive and corrective feedback
   - **Stats**: Updated counter with color-coded percentage

9. **Continuous Loop**: System maintains connection for next shot

4. UI/UX Design Considerations

The user experience is designed to be invisible during practice. The user interacts with the app to start and end a session, but the core value is delivered hands-free.

Screen 1: Login / Paywall:

This is the entry point to the app.

Visuals: A clean, simple screen with the app logo ("LeBot_James"), a strong value proposition ("Real-Time AI Coaching to Perfect Your Jumpshot"), and a single call-to-action button (e.g., "Unlock Pro" or "Start Free Trial").

Functionality: For the MVP, this screen can be a placeholder that simply navigates to the main camera view upon tapping the button. Full implementation would involve StoreKit for subscriptions.

Screen 2: Camera / Training View:

This is the app's primary interface. It will be active for the entire practice session.

Layout: A full-screen, landscape camera view. All UI elements are overlays designed for high visibility against a real-world background (e.g., white text with a drop shadow).

On-Screen Display (OSD): Kept to an absolute minimum.

Shot Counter: A persistent counter in one corner (e.g., Makes: 15 / Total: 25).

Status Indicator: A small icon that subtly indicates the app's state (e.g., "Listening," "Analyzing...").

Controls: A simple "End Session" button.

AR Overlays: These are the primary visual feedback mechanism. They are designed to be transient—appearing for a few seconds after a shot and then fading away to prevent cluttering the view.

Shot Result: A large, clear ✓ or ✗ icon centered on the hoop.

Form Guides (Post-MVP): Simple lines, circles, or arrows to highlight a specific body part mentioned in the audio feedback (e.g., a line showing the ideal elbow angle).

## 5. Technical Implementation Details

### Threading Architecture (CRITICAL)
**Challenge**: UI freezing and "No valid presentationTimeStamp" errors

**Solution**:
- All UI operations on main thread via `DispatchQueue.main.async`
- Camera operations on dedicated background queue
- Vision framework receives CMSampleBuffer preserving timestamps
- WebSocket operations on separate queue

### 1 FPS Processing Strategy
**Challenge**: Balancing real-time feedback with API efficiency

**Solution**:
```swift
private var lastAnalysisTime: TimeInterval = 0
private let analysisInterval: TimeInterval = 1.0 // 1 FPS

func processFrame(_ sampleBuffer: CMSampleBuffer) {
    let currentTime = CACurrentMediaTime()
    if currentTime - lastAnalysisTime >= analysisInterval {
        processFrameForAIAnalysis(sampleBuffer)
    }
}
```

### The GOAT Prompt Engineering
**Challenge**: Consistent, high-quality basketball coaching

**Solution**: Comprehensive system prompt with:
- Persona definition (Michael Jordan/LeBron James spirit)
- Structured analysis process
- Strict JSON output format
- Example responses for consistency

### Security Architecture
**Challenge**: Protecting API credentials

**Solution**: 
- Backend proxy generates ephemeral tokens
- Tokens expire after 30 minutes
- WebSocket uses token authentication
- No API keys stored in client

## 6. Production Status & Future Vision

LeBot_James is now a production-ready AI basketball coaching application that delivers structured, expert-level feedback through "The GOAT" persona. The implementation successfully combines thread-safe architecture, intelligent frame processing, and sophisticated AI integration.

### Key Production Features:
- **Thread-Safe Architecture**: Eliminated UI freezing and Vision framework errors
- **1 FPS AI Processing**: Optimal balance between real-time feedback and efficiency  
- **The GOAT Coaching**: Structured feedback with positive reinforcement and corrective critique
- **Secure Authentication**: Production-ready ephemeral token system
- **Full Landscape Support**: Professional camera experience in all orientations

### Technical Excellence:
```
✅ CMSampleBuffer → UIImage conversion preserving timestamps
✅ Proper main/background thread separation
✅ WebSocket connection with automatic reconnection
✅ Structured JSON responses with comprehensive feedback
✅ 1 FPS throttling for API efficiency
```

### Future Roadmap:
1. **Advanced Analytics**: Shot charts, heat maps, progression tracking
2. **Personalized Training**: AI-generated workout plans based on weaknesses
3. **Social Features**: Share highlights, compete with friends
4. **Expanded Coaching**: Dribbling, defense, and full game analysis

**LeBot_James transforms solo practice into professional training**, providing the immediate feedback loop necessary for rapid improvement. With "The GOAT" as your personal coach, every practice session becomes an opportunity for excellence.