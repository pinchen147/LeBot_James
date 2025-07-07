LeBot_James: AI Basketball Coach – Product Design Document (MVP)
1. Overview

Solo basketball practice is a fundamental part of player development, but it often lacks a critical component: immediate, expert feedback. Players can shoot for hours, unknowingly reinforcing bad habits in their form. LeBot_James is an iOS-based AI basketball coach that watches you practice, providing the real-time analysis and feedback of a personal trainer, right on your iPhone.

The app uses the phone's camera, positioned on a tripod, to observe the player. By intelligently detecting shooting motions through advanced pose analysis and analyzing key frames with Google's Gemini Live API, it provides real-time shot counting and personalized, actionable coaching tips delivered via enhanced audio feedback and rich visual overlays. The system analyzes shooting form, shot trajectory, and the outcome (make or miss) to deliver context-aware feedback after every attempt with Michael Jordan-style authority.

This app is iOS-first, built for simplicity and effectiveness. The MVP is hyper-focused on two core functions: counting shots and providing passive coaching to improve a player's form. The system design emphasizes:

Hands-Free Operation: Set up your phone on a tripod, start the session, and practice without interruption.

Real-Time Shot Counting: An on-screen counter automatically tracks makes and total attempts.

Per-Shot AI Coaching: After each shot, receive concise audio feedback with Michael Jordan-style authority based on real-time AI analysis of your form, delivered with outcome-specific voice modulation.

Rich Visual Feedback: SwiftUI overlays provide instant visual confirmation with enhanced animations, color-coded shooting percentages, and contextual coaching tips displayed directly over the camera feed.

Real-Time AI Analysis: The app uses Google Gemini Live API via WebSocket connection for low-latency, real-time analysis, eliminating the traditional request-response delays of standard API calls.

Minimalist Interface: The app consists of only two primary screens: a simple entry/paywall screen and the main camera view where all the action happens.

LeBot_James aims to be the ultimate practice partner, making every training session more productive by providing the immediate feedback loop necessary for meaningful improvement.

2. Feature Overview (MVP)

The MVP will focus on delivering a tight, valuable feedback loop with just two core features.

Feature	Description	Implementation Details
1. **ENHANCED** Automatic Shot Counting	The app detects each shot attempt through advanced pose analysis and outcome determination, displaying enhanced visual feedback with shooting statistics.	**Advanced Computer Vision**: Uses VNDetectHumanBodyPoseRequest to analyze shooting motion transitions from stance to release. Smart frame selection sends optimal frames to Gemini Live API for real-time outcome analysis. **Rich UI**: Displays makes/total with color-coded percentages (green: 80%+, yellow: 60-79%, orange: 40-59%, red: <40%). Enhanced animations with spring transitions and contextual feedback overlays.
2. **ENHANCED** Real-Time AI Coaching	After each shot, the AI provides contextual audio feedback with Michael Jordan-style authority, enhanced by outcome-specific voice modulation and comprehensive coaching knowledge.	**Live API Integration**: Direct WebSocket connection to Gemini Live API (gemini-2.0-flash-exp) for low-latency analysis. **Enhanced Audio**: AVSpeechSynthesizer with outcome-based voice settings, proper audio session management, and authoritative delivery. **Contextual Tips**: Comprehensive coaching_tips.json with categorized feedback (general tips, makes, misses, encouragement) for dynamic, non-repetitive coaching. **Smart Prompting**: Advanced prompt engineering with specific basketball coaching instructions and avoidance of previous tips.
3. **UPDATED** System Architecture

The architecture is streamlined for real-time performance with direct API integration and enhanced local intelligence.

```
iPhone (Client App)
├─ Camera Integration              - AVCaptureSession with proper permissions and background processing
├─ Training Session Manager        - **ENHANCED**: Core orchestrator with state management and coordination
│   ├─ Shot Event Detector         - **ENHANCED**: Advanced pose analysis with VNDetectHumanBodyPoseRequest
│   ├─ Smart Frame Selector        - Intelligent frame selection for optimal AI analysis
│   ├─ Gemini Live API Client      - **NEW**: Real-time WebSocket client for low-latency communication
│   ├─ Coaching Tips Manager       - **NEW**: Local coaching knowledge base with contextual selection
│   └─ Response Renderer           - Visual feedback coordination and audio session management
├─ Enhanced Audio System           - **ENHANCED**: AVSpeechSynthesizer with outcome-based modulation
└─ Rich UI Layer (SwiftUI)         - **ENHANCED**: Advanced overlays, animations, and color-coded feedback

Cloud Services
└─ Google Gemini Live API          - **NEW**: Real-time WebSocket connection (gemini-2.0-flash-exp)
    ├─ Low-latency image analysis
    ├─ Session management & resumption  
    └─ JSON response streaming
```

**Key Architectural Improvements:**
- **Direct Live API Integration**: Eliminates proxy complexity and reduces latency
- **Enhanced Local Intelligence**: Advanced pose detection and contextual tip management
- **Real-Time Communication**: WebSocket-based streaming for immediate feedback
- **Rich Visual Experience**: Color-coded statistics and enhanced animations

**ENHANCED** Typical Session Flow:

**Setup**: Jordan places their iPhone on a tripod, opens LeBot_James, and taps "Start Training" on the enhanced login screen.

**Real-Time Connection**: The app establishes a WebSocket connection to Gemini Live API and configures the camera with proper permissions.

**Advanced Monitoring**: The Shot Event Detector continuously analyzes pose data using VNDetectHumanBodyPoseRequest, detecting shooting stance transitions.

**Intelligent Shot Detection**: Jordan takes a shot. The system detects the shooting motion sequence (stance → release) and triggers analysis.

**Smart Frame Selection**: The Smart Frame Selector identifies the optimal release frame for form analysis.

**Live AI Analysis**: The frame is sent via WebSocket to Gemini Live API with an enhanced prompt: "You are LeBot James, an AI basketball coach. Analyze this shot with Michael Jordan-style authority..."

**Real-Time Response**: Gemini processes and streams back JSON response with outcome and coaching tip in under 1 second.

**Enhanced Feedback Rendering**:
- **Visual**: Rich overlay with enhanced animations - large checkmark/X, "SWISH!" or "KEEP SHOOTING!", coaching tip text, and color-coded borders
- **Audio**: Outcome-specific voice modulation delivers coaching tip with authority
- **Statistics**: Real-time counter update with color-coded shooting percentage

**Contextual Enhancement**: CoachingTipsManager provides fallback tips and prevents repetition.

**Continuous Loop**: System immediately returns to monitoring, maintaining WebSocket connection for minimal latency on subsequent shots.

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

5. **UPDATED** Technical Challenges and Solutions

**Real-Time Performance & Low Latency**: **SOLVED** - The challenge was analyzing high-speed basketball actions with minimal delay.

**Solution Implemented**: Direct integration with Gemini Live API via WebSocket eliminates traditional request-response delays. Combined with advanced pose detection for precise shot timing, the system achieves sub-second feedback cycles.

**AI Accuracy & Coaching Quality**: **ENHANCED** - Ensuring relevant, non-repetitive basketball coaching.

**Solution Implemented**: 
- Advanced prompt engineering with specific basketball coaching instructions
- Comprehensive coaching_tips.json with categorized feedback (general, makes, misses, encouragement)
- CoachingTipsManager prevents repetition and provides contextual fallbacks
- Michael Jordan-style authority in feedback delivery

**Shot Detection Accuracy**: **SOLVED** - Reliable detection of basketball shooting motions.

**Solution Implemented**: 
- VNDetectHumanBodyPoseRequest analyzes shooting pose transitions
- Multi-criteria shooting stance detection (hand elevation, elbow alignment, hand proximity)
- Fallback simulation system for testing and edge cases
- Smart frame buffering for optimal analysis timing

**Environmental Adaptability**: **ENHANCED** - Handling varied lighting and court conditions.

**Solution Implemented**:
- Smart frame quality assessment with brightness and resolution checks
- Robust camera configuration with proper session management
- Enhanced error handling and user feedback for setup issues
- Background processing optimization for consistent performance

**Cost Efficiency**: **OPTIMIZED** - Managing API costs while maintaining quality.

**Solution Implemented**:
- Intelligent frame selection sends only optimal frames
- Local coaching knowledge base reduces dependency on AI-generated tips
- Efficient WebSocket connection reuse
- Smart analysis triggering only on detected shot events

6. **UPDATED** Conclusion

LeBot_James has evolved into a sophisticated, real-time AI basketball coaching application that delivers immediate, authoritative feedback to players. By leveraging advanced computer vision, Google's Gemini Live API, and enhanced user experience design, the app transforms a standard iPhone into a personal shooting coach with Michael Jordan-style authority.

**Key Achievements in Current Implementation:**
- **Real-Time Performance**: Sub-second feedback through Gemini Live API WebSocket integration
- **Advanced Shot Detection**: Sophisticated pose analysis with VNDetectHumanBodyPoseRequest
- **Rich User Experience**: Color-coded statistics, enhanced animations, and contextual feedback
- **Intelligent Coaching**: Comprehensive coaching knowledge base with non-repetitive, outcome-specific feedback
- **Professional Audio**: Outcome-based voice modulation for authoritative coaching delivery

The MVP successfully delivers on its core promise—shot counting and intelligent coaching—while establishing a robust foundation for future enhancements. The architecture combines cutting-edge AI capabilities with practical engineering excellence, creating an MVP that feels like a finished product.

**Future Roadmap**: The current implementation provides clear pathways for advanced features including detailed analytics, personalized training programs, multi-player sessions, and expanded coaching knowledge bases. By making every practice session smarter and more engaging, LeBot_James is positioned to become the definitive AI basketball coach for serious players.