#!/bin/bash

# substitute-env-vars.sh
# This script substitutes environment variables in Info.plist during build

set -e

# Function to print colored output
print_info() {
    echo "🔧 [INFO] $1"
}

print_warning() {
    echo "⚠️ [WARNING] $1"
}

print_error() {
    echo "❌ [ERROR] $1"
}

print_success() {
    echo "✅ [SUCCESS] $1"
}

# Get the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Path to .env file
ENV_FILE="$PROJECT_DIR/.env"

print_info "Starting environment variable substitution..."
print_info "Project directory: $PROJECT_DIR"
print_info "Looking for .env file at: $ENV_FILE"

# Check if .env file exists
if [[ ! -f "$ENV_FILE" ]]; then
    print_warning ".env file not found at $ENV_FILE"
    print_info "Creating .env file from template..."
    
    # Create .env file from template if it doesn't exist
    cat > "$ENV_FILE" << 'EOF'
# LeBot James Environment Variables
# Fill in your actual API keys below

# Google Gemini API Key
# Get this from: https://makersuite.google.com/app/apikey
GEMINI_API_KEY=your_gemini_api_key_here

# Optional: Analytics and Crash Reporting
ANALYTICS_ID=your_analytics_id_here
CRASH_REPORTING_KEY=your_crash_reporting_key_here
EOF
    
    print_warning "Created .env file with placeholder values. Please update with your actual API keys!"
    print_error "Build will fail until you provide real API keys in .env file"
    exit 1
fi

# Source the .env file to load variables
print_info "Loading environment variables from .env file..."
set -a  # automatically export all variables
source "$ENV_FILE"
set +a  # stop auto-exporting

# Validate required variables
if [[ -z "$GEMINI_API_KEY" || "$GEMINI_API_KEY" == "your_gemini_api_key_here" ]]; then
    print_error "GEMINI_API_KEY is not set or still has placeholder value"
    print_info "Please edit $ENV_FILE and set your actual Gemini API key"
    exit 1
fi

print_success "Environment variables loaded successfully"
print_info "GEMINI_API_KEY: ${GEMINI_API_KEY:0:8}..." # Show only first 8 chars for security

# The variables are now available as environment variables for Xcode to use
# Xcode will automatically substitute $(GEMINI_API_KEY) in Info.plist with the actual value

print_success "Environment variable substitution completed" 