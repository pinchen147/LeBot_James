# Live API Troubleshooting Guide

## Quick Fixes Applied

1. **Model Name**: Changed from `gemini-2.0-flash-001` to `gemini-2.0-flash-live-001`
   - The Live API requires the specific "-live" variant of the model

2. **Video Streaming**: Updated to use proper `realtimeInput` with `video` field
   - Changed from deprecated `mediaChunks` to `video` field
   - Added separate methods for video streaming vs image analysis

3. **Connection Handling**: Enhanced error handling and connection state management
   - Added proper WebSocket delegate methods
   - Improved connection error diagnostics

## Common Issues and Solutions

### 1. WebSocket Connection Closes Immediately (Code 1007)

**Symptoms:**
```
❌ WebSocket connection closed with code: NSURLSessionWebSocketCloseCode(rawValue: 1007)
```

**Solutions:**
- Verify API key has access to Gemini 2.0 Flash Live API
- Use the correct model name: `gemini-2.0-flash-live-001`
- Ensure proper JSON format in setup message

### 2. Socket Not Connected Error

**Symptoms:**
```
❌ WebSocket receive error: Error Domain=NSPOSIXErrorDomain Code=57 "Socket is not connected"
```

**Solutions:**
- Check network connectivity
- Verify firewall settings allow WebSocket connections
- Test with diagnostic script: `./Scripts/diagnose-connection.sh`

### 3. API Key Issues

**Verify your API key:**
```bash
# Check if API key is configured
grep "geminiAPIKey" "LeBot James/Configuration/Config.swift"

# Test REST API access
API_KEY="your-key-here"
curl -s "https://generativelanguage.googleapis.com/v1beta/models?key=$API_KEY" | head
```

### 4. Model Access Issues

**Available Live API Models:**
- `gemini-2.0-flash-live-001` - Recommended for video analysis
- `gemini-live-2.5-flash-preview` - Alternative option
- `gemini-2.5-flash-preview-native-audio-dialog` - For native audio

## Development vs Production

### Development Mode (Current)
- Direct API key connection: `?key=YOUR_API_KEY`
- Good for testing and development
- Security risk if deployed to production

### Production Mode (Recommended)
1. Deploy the Backend service
2. Use ephemeral tokens: `?access_token=EPHEMERAL_TOKEN`
3. Update Config.swift with backend URL
4. Enable token fetching in TrainingSessionManager

## Testing the Connection

### 1. Run Diagnostic Script
```bash
./Scripts/diagnose-connection.sh
```

### 2. Test WebSocket Manually
```bash
# Install websocat if needed
brew install websocat

# Test connection
API_KEY=$(grep "geminiAPIKey" "LeBot James/Configuration/Config.swift" | cut -d'"' -f2)
echo '{"setup":{"model":"models/gemini-2.0-flash-live-001","generationConfig":{"responseModalities":["TEXT"]}}}' | \
websocat "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=$API_KEY"
```

### 3. Monitor Xcode Console
Look for these success messages:
- ✅ Direct WebSocket connection to Gemini Live API established
- ✅ Session setup complete
- ✅ Live API connected

## Performance Tips

1. **Use Low Media Resolution**: Already configured in setup
2. **Optimize Frame Rate**: Send frames every 1-2 seconds, not continuously
3. **Compress Images**: Using JPEG at 0.8 quality
4. **Handle Interruptions**: Implement proper VAD handling

## Next Steps

If issues persist:
1. Check [Google AI Studio](https://aistudio.google.com) to verify API key permissions
2. Try the alternative model: `gemini-live-2.5-flash-preview`
3. Enable verbose logging in GeminiLiveClient
4. Contact Google Cloud support for API access issues 