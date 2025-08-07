#!/bin/bash
# File: drive-sync/start.sh
# Start script for Google Drive sync service (follows log-viewer/start.sh pattern)

# Check if sync should be enabled
if [ "$ENABLE_GDRIVE_SYNC" = "false" ]; then
    echo "Google Drive sync is disabled (ENABLE_GDRIVE_SYNC=false)"
    exit 0
fi

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
if [ -f /tmp/drive-sync.pid ]; then
    PID=$(cat /tmp/drive-sync.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "Drive sync is already running (PID: $PID)"
        exit 0
    else
        echo "Removing stale PID file"
        rm /tmp/drive-sync.pid
    fi
fi

# Activate virtual environment
source /workspace/venvs/drive-sync/bin/activate

# Start the sync service
LOG_FILE="/workspace/logs/drive-sync/sync_$(date +%Y%m%d_%H%M%S).log"
echo "Starting Google Drive sync service..."
echo "Log file: $LOG_FILE"

nohup python /drive-sync/gdrive_sync.py > "$LOG_FILE" 2>&1 &
PID=$!

# Save PID
echo $PID > /tmp/drive-sync.pid

echo "Drive sync started successfully (PID: $PID)"

deactivate
