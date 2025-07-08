# LeBot James: Real Time AI Basketball Coach 🏀

Transform your solo basketball practice into professional training sessions with real-time AI coaching powered by Google's Gemini 2.0 Flash.

![iOS 17.0+](https://img.shields.io/badge/iOS-17.0+-blue.svg)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0+-green.svg)
![Production Ready](https://img.shields.io/badge/Status-Production%20Ready-success.svg)

## Overview

LeBot_James is your personal AI basketball coach that watches you practice and provides immediate, expert-level feedback on every shot. Using advanced computer vision and "The GOAT" AI persona—embodying the spirit of Michael Jordan and LeBron James—the app delivers structured coaching that helps you perfect your jumpshot.

### Key Features

- **🎯 Automatic Shot Counting**: Advanced trajectory detection tracks makes and misses with color-coded statistics
- **🤖 Real-Time AI Coaching**: 1 FPS analysis with sub-second feedback via Gemini Live API
- **🎙️ The GOAT Persona**: Expert coaching voice combining Michael Jordan's intensity with LeBron's wisdom
- **📱 Hands-Free Operation**: Set up your phone on a tripod and focus on your practice
- **🔄 Full Landscape Support**: Professional camera experience in all orientations
- **🔒 Secure Architecture**: Production-ready ephemeral token authentication

## Quick Start

### Prerequisites

- iOS 17.0+ device (iPhone)
- Xcode 15.0+
- Swift 5.9+
- Tripod or phone stand for optimal camera positioning
- Backend server setup (see Backend Setup section)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/lebot-james.git
   cd lebot-james
   ```

2. **Configure API credentials**
   ```bash
   ./Scripts/setup-config.sh
   ```

3. **Open in Xcode**
   ```bash
   open "LeBot James.xcodeproj"
   ```

4. **Build and run**
   - Select your target device
   - Press `Cmd+R` to build and run

## Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        iPhone App                            │
├─────────────────────────────────────────────────────────────┤
│  CameraTrainingView (SwiftUI)                              │
│       ↓                                                     │
│  TrainingSessionManager (1 FPS Processing)                 │
│       ├── ShotEventDetector (Vision Framework)             │
│       ├── GeminiLiveClient (WebSocket)                     │
│       ├── SessionAuthService (Ephemeral Tokens)            │
│       └── ResponseRenderer (Visual Feedback)               │
├─────────────────────────────────────────────────────────────┤
│                    Threading Model                          │
│  • Main Thread: UI Updates                                 │
│  • Camera Queue: AVCaptureSession                          │
│  • Vision Queue: Trajectory Detection                      │
│  • Network Queue: WebSocket Communication                  │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Cloud Services                           │
├─────────────────────────────────────────────────────────────┤
│  Gemini Live API (gemini-2.0-flash-exp)                   │
│  • Real-time WebSocket connection                          │
│  • Structured JSON responses                               │
│  • The GOAT coaching persona                              │
├─────────────────────────────────────────────────────────────┤
│  Backend Proxy Server (Node.js)                            │
│  • Ephemeral token generation                              │
│  • Rate limiting & security                                │
└─────────────────────────────────────────────────────────────┘
```

### Core Components

| Component | Description |
|-----------|-------------|
| **TrainingSessionManager** | Orchestrates 1 FPS frame processing and AI analysis |
| **ShotEventDetector** | Uses VNDetectTrajectoriesRequest for motion detection |
| **GeminiLiveClient** | WebSocket client for real-time AI communication |
| **The GOAT Prompt** | Sophisticated system prompt for expert coaching |
| **CoachResponse** | Structured data model for AI feedback |

## Usage

### Basic Practice Session

1. **Launch the app** and tap "Start Training"
2. **Position your phone** on a tripod with clear view of the basket
3. **Start shooting** - the app automatically detects and analyzes each shot
4. **Receive feedback** through audio coaching and visual overlays
5. **Track progress** with real-time shot statistics

### AI Coaching Response Format

The GOAT provides structured feedback for every shot:

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

## Backend Setup

The app requires a Node.js backend server for secure authentication:

1. **Navigate to backend directory**
   ```bash
   cd Backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your Gemini API credentials
   ```

4. **Start server**
   ```bash
   npm start
   ```

## Development

### Project Structure

```
LeBot James/
├── LeBot_JamesApp.swift              # App entry point
├── Configuration/
│   ├── Config.swift                  # API configuration
│   └── CoachingPrompts.swift         # The GOAT system prompt
├── Managers/
│   ├── TrainingSessionManager.swift  # Core orchestrator
│   ├── ShotEventDetector.swift       # Vision processing
│   └── GeminiLiveClient.swift        # WebSocket client
├── Views/
│   ├── CameraTrainingView.swift      # Main UI
│   └── ARViewRepresentable.swift     # Camera integration
├── Backend/                          # Node.js proxy server
└── Scripts/                          # Development tools
```

### Testing

Run diagnostic scripts to verify setup:

```bash
# Test Live API connectivity
./Scripts/test-live-api.sh

# Diagnose connection issues
./Scripts/diagnose-connection.sh
```

### Key Technical Features

- **Thread-Safe Architecture**: Proper main/background thread separation
- **1 FPS Processing**: Optimal balance of real-time feedback and API efficiency
- **CMSampleBuffer Handling**: Preserves timestamps for accurate trajectory detection
- **Structured AI Responses**: Consistent JSON format for reliable parsing
- **Automatic Reconnection**: Robust WebSocket connection management

## Performance Metrics

- **AI Response Time**: < 1 second via WebSocket
- **Frame Processing**: 1 FPS with intelligent throttling
- **Shot Detection Accuracy**: High precision trajectory analysis
- **Memory Usage**: Optimized image conversion pipeline
- **Battery Impact**: Minimal with efficient processing

## Future Roadmap

- [ ] Advanced shot analytics and heat maps
- [ ] Personalized training plans based on weaknesses
- [ ] Social features for sharing highlights
- [ ] Expanded coaching for dribbling and defense
- [ ] Apple Watch integration for biometric data

## Contributing

We welcome contributions!

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Google Gemini team for the powerful 2.0 Flash model
- Apple Vision framework for advanced trajectory detection
- The basketball community for inspiration and feedback

---

**LeBot_James** - *Where Every Practice Makes Perfect* 🏀✨

Built with passion for the game and powered by cutting-edge AI.
