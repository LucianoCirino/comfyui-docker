#!/bin/bash
set -e

# Create and activate virtual environment
echo "Creating virtual environment for drive-sync..."
python3 -m venv /workspace/venvs/drive-sync

echo "Activating virtual environment..."
source /workspace/venvs/drive-sync/bin/activate

echo "Installing Google Drive sync dependencies..."
pip install --upgrade pip
pip install \
    google-auth==2.23.4 \
    google-auth-oauthlib==1.1.0 \
    google-auth-httplib2==0.1.1 \
    google-api-python-client==2.108.0 \
    watchdog==3.0.0

echo "Drive sync dependencies installed successfully!"

# Create necessary directories
mkdir -p /workspace/logs/drive-sync

deactivate

