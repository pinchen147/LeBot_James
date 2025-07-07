#!/bin/bash

# setup-config.sh
# Setup script for LeBot James configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}🔧 [INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️ [WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}❌ [ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ [SUCCESS]${NC} $1"
}

# Get the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

print_info "LeBot James Configuration Setup"
print_info "==============================="

# Check if Config.swift already exists
CONFIG_FILE="$PROJECT_DIR/LeBot James/Configuration/Config.swift"
TEMPLATE_FILE="$PROJECT_DIR/LeBot James/Configuration/Config.swift.template"

if [[ -f "$CONFIG_FILE" ]]; then
    print_warning "Config.swift already exists"
    read -p "Do you want to recreate it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Keeping existing Config.swift"
        exit 0
    fi
fi

# Check if template exists
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    print_error "Config.swift.template not found at $TEMPLATE_FILE"
    exit 1
fi

# Copy template to Config.swift
print_info "Creating Config.swift from template..."
cp "$TEMPLATE_FILE" "$CONFIG_FILE"

print_success "Config.swift created!"
print_info ""
print_info "🔑 Next Steps:"
print_info "1. Get your Gemini API key from: https://makersuite.google.com/app/apikey"
print_info "2. Open: LeBot James/Configuration/Config.swift"
print_info "3. Replace 'YOUR_GEMINI_API_KEY_HERE' with your actual API key"
print_info ""
print_warning "Remember: Config.swift is in .gitignore and won't be committed to git"
print_success "Setup complete! 🚀" 