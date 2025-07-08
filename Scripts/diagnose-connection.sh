#!/bin/bash

# Diagnostic script for LeBot James connection issues

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}LeBot James Connection Diagnosis${NC}"
echo -e "${BLUE}================================${NC}\n"

# Check API key
echo -e "${YELLOW}1. Checking API Key...${NC}"
API_KEY=$(grep "geminiAPIKey" "LeBot James/Configuration/Config.swift" 2>/dev/null | cut -d'"' -f2)

if [ -z "$API_KEY" ] || [ "$API_KEY" == "YOUR_GEMINI_API_KEY_HERE" ]; then
    echo -e "${RED}❌ No valid API key found${NC}"
    echo "   Please add your API key to Config.swift"
    exit 1
else
    echo -e "${GREEN}✅ API key found${NC}"
    echo "   Key starts with: ${API_KEY:0:8}..."
fi

# Check network connectivity
echo -e "\n${YELLOW}2. Checking Network Connectivity...${NC}"
if ping -c 1 google.com &> /dev/null; then
    echo -e "${GREEN}✅ Internet connection OK${NC}"
else
    echo -e "${RED}❌ No internet connection${NC}"
    exit 1
fi

# Check DNS resolution for Gemini API
echo -e "\n${YELLOW}3. Checking Gemini API DNS...${NC}"
if host generativelanguage.googleapis.com &> /dev/null; then
    echo -e "${GREEN}✅ DNS resolution OK${NC}"
else
    echo -e "${RED}❌ Cannot resolve Gemini API hostname${NC}"
fi

# Test REST API connection
echo -e "\n${YELLOW}4. Testing REST API Connection...${NC}"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-001?key=$API_KEY" 2>/dev/null)

if [ "$RESPONSE" == "200" ]; then
    echo -e "${GREEN}✅ REST API connection successful${NC}"
elif [ "$RESPONSE" == "401" ] || [ "$RESPONSE" == "403" ]; then
    echo -e "${RED}❌ API key is invalid or unauthorized${NC}"
elif [ "$RESPONSE" == "429" ]; then
    echo -e "${RED}❌ API rate limit exceeded${NC}"
else
    echo -e "${RED}❌ REST API connection failed (HTTP $RESPONSE)${NC}"
fi

# Check WebSocket support
echo -e "\n${YELLOW}5. Checking WebSocket Tools...${NC}"
if command -v websocat &> /dev/null; then
    echo -e "${GREEN}✅ websocat installed${NC}"
elif command -v wscat &> /dev/null; then
    echo -e "${GREEN}✅ wscat installed${NC}"
else
    echo -e "${YELLOW}⚠️  No WebSocket testing tools found${NC}"
    echo "   Install with: brew install websocat"
fi

# Test WebSocket connection
echo -e "\n${YELLOW}6. Testing WebSocket Connection...${NC}"
WS_URL="wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=$API_KEY"

if command -v websocat &> /dev/null; then
    echo "Testing WebSocket handshake..."
    SETUP='{"setup":{"model":"models/gemini-2.0-flash-001","generationConfig":{"responseModalities":["TEXT"]}}}'
    
    # Test connection
    RESULT=$(echo "$SETUP" | websocat -t -n1 "$WS_URL" 2>&1 | head -5)
    
    if echo "$RESULT" | grep -q "setupComplete"; then
        echo -e "${GREEN}✅ WebSocket connection successful${NC}"
    elif echo "$RESULT" | grep -q "401\|403"; then
        echo -e "${RED}❌ WebSocket authentication failed${NC}"
        echo "   Check your API key permissions"
    else
        echo -e "${RED}❌ WebSocket connection failed${NC}"
        echo "   Response: $RESULT"
    fi
fi

# Check for common issues
echo -e "\n${YELLOW}7. Common Issues Check...${NC}"

# Check if backend is running (for ephemeral tokens)
if lsof -i :3000 &> /dev/null; then
    echo -e "${GREEN}✅ Backend service is running on port 3000${NC}"
else
    echo -e "${YELLOW}ℹ️  Backend service not running (OK if using direct API key)${NC}"
fi

# Summary
echo -e "\n${BLUE}================================${NC}"
echo -e "${BLUE}Diagnosis Complete${NC}"
echo -e "${BLUE}================================${NC}\n"

echo "If you're still experiencing issues:"
echo "1. Ensure your API key has access to Gemini 2.0 Flash"
echo "2. Check if you're behind a firewall that blocks WebSocket connections"
echo "3. Try restarting the app and Xcode"
echo "4. Check the Xcode console for detailed error messages" 