#!/bin/bash
# File: /scripts/setup_gdrive_sync.sh
# Setup script for Google Drive sync service

echo "Setting up Google Drive sync service..."

# Create virtual environment
VENV_PATH="/workspace/gdrive_sync_venv"
if [ ! -d "$VENV_PATH" ]; then
    echo "Creating virtual environment..."
    python3 -m venv $VENV_PATH
fi

# Activate virtual environment
source $VENV_PATH/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install --upgrade pip
pip install \
    google-auth==2.23.4 \
    google-auth-oauthlib==1.1.0 \
    google-auth-httplib2==0.1.1 \
    google-api-python-client==2.108.0 \
    watchdog==3.0.0

# Create directories
mkdir -p /workspace/gdrive_sync_logs

echo "Google Drive sync setup complete!"

# Check if credentials exist
if [ ! -f "/workspace/credentials.json" ]; then
    echo ""
    echo "⚠️  IMPORTANT: Google Drive credentials not found!"
    echo ""
    echo "To enable Google Drive sync:"
    echo "1. Go to https://console.cloud.google.com/"
    echo "2. Enable Google Drive API"
    echo "3. Create OAuth 2.0 credentials (Desktop type)"
    echo "4. Download credentials.json"
    echo "5. Place it at /workspace/credentials.json"
    echo ""
    echo "Or set GDRIVE_CREDS_JSON as a RunPod secret"
else
    echo "✓ Google Drive credentials found"
fi
