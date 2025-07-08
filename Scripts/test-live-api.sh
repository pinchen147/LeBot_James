#!/bin/bash

# Test script for Live API connection

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Testing Gemini Live API Connection...${NC}"

# Get API key from Config.swift
API_KEY=$(grep "geminiAPIKey" "LeBot James/Configuration/Config.swift" | cut -d'"' -f2)

if [ "$API_KEY" == "YOUR_GEMINI_API_KEY_HERE" ] || [ -z "$API_KEY" ]; then
    echo -e "${RED}❌ No valid API key found in Config.swift${NC}"
    exit 1
fi

echo -e "${GREEN}✅ API key found${NC}"

# Test WebSocket connection to Live API
WEBSOCKET_URL="wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=${API_KEY}"

echo -e "${YELLOW}Testing WebSocket connection...${NC}"

# Create a simple setup message
SETUP_MESSAGE='{
  "setup": {
    "model": "models/gemini-2.0-flash-001",
    "generationConfig": {
      "responseModalities": ["TEXT"]
    }
  }
}'

# Use curl to test the connection (requires curl 7.86.0 or later for WebSocket support)
if command -v websocat &> /dev/null; then
    echo -e "${YELLOW}Using websocat to test connection...${NC}"
    echo "$SETUP_MESSAGE" | websocat -n1 "$WEBSOCKET_URL" 2>&1 | head -20
else
    echo -e "${YELLOW}Installing websocat for testing...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install websocat 2>/dev/null || echo "Failed to install websocat"
    fi
fi

echo -e "${GREEN}✅ Test complete${NC}" 