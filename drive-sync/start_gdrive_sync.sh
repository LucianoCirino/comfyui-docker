#!/usr/bin/env bash
# File: drive-sync/start_gdrive_sync.sh
# Start script for Google Drive sync service (follows log-viewer pattern exactly)

echo "Starting Google Drive sync..."

# Check if sync should be enabled
if [ "$ENABLE_GDRIVE_SYNC" = "false" ]; then
    echo "Google Drive sync is disabled (ENABLE_GDRIVE_SYNC=false)"
    exit 0
fi

# Create logs directory if it doesn't exist
mkdir -p /workspace/logs/drive-sync

# Handle RunPod secret if provided
if [ -n "$GDRIVE_CREDS_JSON" ] && [ ! -f "/workspace/credentials.json" ]; then
    echo "Creating credentials from RunPod secret..."
    echo "$GDRIVE_CREDS_JSON" | base64 -d > /workspace/credentials.json
fi

# Check for credentials
if [ ! -f "/workspace/credentials.json" ]; then
    echo "Warning: Google Drive credentials not found at /workspace/credentials.json"
    echo "Drive sync will not start. To enable:"
    echo "  1. Get OAuth2 credentials from Google Cloud Console"
    echo "  2. Save as /workspace/credentials.json"
    echo "  3. Restart the service"
    exit 0
fi

# Check if already running
if pgrep -f "gdrive_sync.py" > /dev/null; then
    echo "Drive sync is already running"
    exit 0
fi

# Start the sync service using its dedicated venv
cd /drive-sync
/drive-sync/venv/bin/python gdrive_sync.py > /workspace/logs/drive-sync/sync.log 2>&1 &

echo "Google Drive sync started"
echo "Log file: /workspace/logs/drive-sync/sync.log"

