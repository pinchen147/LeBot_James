# LeBot_James: AI Basketball Coach

An iOS app that provides real-time AI coaching for basketball shooting practice using computer vision and machine learning.

## Features

- **Automatic Shot Detection**: Uses computer vision to detect when you take a shot
- **Real-time AI Coaching**: Powered by Gemini 2.0 Flash via Live API for ultra-low latency
- **Direct WebSocket Connection**: Client connects directly to Gemini for minimal delay
- **Shot Counter**: Tracks makes and misses with visual AR overlays
- **Voice Feedback**: Audio coaching tips delivered via text-to-speech
- **AR Visualization**: Augmented reality overlays show shot results and form guidance
- **Ephemeral Token Support**: Production-ready security with short-lived tokens

## Prerequisites

- iOS 15.0 or later
- ARKit-compatible device (iPhone 6s or newer)
- Xcode 14.0 or later
- Google Gemini API key

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd "LeBot James"
```

### 2. Configure API Keys

**Option A: Quick Setup (Recommended)**
```bash
# Run the setup script
./Scripts/setup-config.sh
```

**Option B: Manual Setup**
1. Copy the template file:
   ```bash
   cp "LeBot James/Configuration/Config.swift.template" "LeBot James/Configuration/Config.swift"
   ```

2. Edit `LeBot James/Configuration/Config.swift`:
   ```swift
   // Replace this line:
   static let geminiAPIKey = "YOUR_GEMINI_API_KEY_HERE"
   
   // With your actual API key:
   static let geminiAPIKey = "your_actual_gemini_api_key_here"
   ```

### 3. Build and Run

1. Open `LeBot James.xcodeproj` in Xcode
2. Select your target device or simulator
3. Press Cmd+R to build and run

## Usage

1. **Setup**: Place your iPhone on a tripod pointing towards the basketball hoop
2. **Start Session**: Tap "Start Training" to begin your practice session
3. **Practice**: Take shots as normal - the app will automatically detect them
4. **Get Feedback**: Listen to audio coaching tips after each shot
5. **Track Progress**: View your makes/misses counter in real-time

## Architecture

### Live API Integration
The app uses Google's Gemini Live API for real-time shot analysis:
- **Direct WebSocket Connection**: Bypasses backend proxy for minimal latency
- **Gemini 2.0 Flash**: Optimized for fast video/image analysis
- **Ephemeral Tokens**: Short-lived tokens for secure client-side connections
- **Fallback Support**: Automatically switches to REST API if Live API is unavailable

The app follows a clean architecture pattern:

- **Views**: SwiftUI interfaces for login and camera training
- **Managers**: Core business logic components
  - `TrainingSessionManager`: Orchestrates the training session
  - `ShotEventDetector`: Detects basketball shots using computer vision
  - `SmartFrameSelector`: Selects optimal frames for AI analysis
  - `AIAnalysisClient`: Interfaces with Google Gemini API
  - `ResponseRenderer`: Handles AR overlays and visual feedback
- **Configuration**: App settings and secure secrets management

## Security

- API keys are stored in `Config.swift` (excluded from git via `.gitignore`)
- Configuration template (`Config.swift.template`) is committed for easy setup
- The `Config` struct provides type-safe access to configuration values
- Uses conventional Swift patterns for secrets management

## API Keys

### Google Gemini API
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create a new API key
3. Add it to your `Config.swift` file

### Backend Token Service (Optional for Production)
For production deployments with ephemeral tokens:
```bash
cd Backend
npm install
npm run dev  # For local testing
```
Update `Config.swift` with your deployed backend URL.

## Development

### Project Structure
```
LeBot James/
├── Views/                 # SwiftUI views
│   ├── LoginView.swift
│   ├── CameraTrainingView.swift
│   └── ARViewRepresentable.swift
├── Managers/              # Core business logic
│   ├── TrainingSessionManager.swift
│   ├── ShotEventDetector.swift
│   ├── SmartFrameSelector.swift
│   ├── AIAnalysisClient.swift
│   └── ResponseRenderer.swift
├── Configuration/         # App configuration
│   ├── AppConfig.swift
│   ├── Config.swift           # Your API keys (not in git)
│   ├── Config.swift.template  # Template for setup
│   └── Secrets.swift          # Legacy (deprecated)
├── Scripts/               # Build and setup scripts
│   ├── setup-config.sh        # Quick setup script
│   └── substitute-env-vars.sh # Legacy build script
└── Assets.xcassets/       # App assets
```

### Key Technologies
- **SwiftUI**: Modern iOS UI framework
- **ARKit**: Augmented reality overlays
- **Vision**: Computer vision for motion detection
- **AVFoundation**: Text-to-speech audio feedback
- **Google Gemini API**: AI-powered shot analysis and coaching

## Troubleshooting

### Build Issues
- Ensure `Config.swift` exists in `LeBot James/Configuration/`
- Run `./Scripts/setup-config.sh` if `Config.swift` is missing
- Verify your API key is set in `Config.swift` (not the template file)
- Check that your Gemini API key is valid and active

### Runtime Issues
- Grant camera permissions when prompted
- Ensure good lighting conditions for shot detection
- Position camera to clearly see both player and hoop

### API Issues
- Verify your Gemini API key is active and has sufficient quota
- Check your internet connection for API calls

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is for educational and personal use.

## Support

For issues and questions, please check the troubleshooting section above or create an issue in the repository.