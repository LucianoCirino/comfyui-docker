#!/bin/bash
# File: /scripts/start_gdrive_sync.sh
# Startup script for Google Drive sync service

# Check if we should enable sync
if [ "$ENABLE_GDRIVE_SYNC" = "false" ]; then
    echo "Google Drive sync disabled (ENABLE_GDRIVE_SYNC=false)"
    exit 0
fi

# Check for RunPod secret and create credentials file if needed
if [ -n "$GDRIVE_CREDS_JSON" ] && [ ! -f "/workspace/credentials.json" ]; then
    echo "Creating credentials from RunPod secret..."
    echo "$GDRIVE_CREDS_JSON" | base64 -d > /workspace/credentials.json
fi

# Check if credentials exist
if [ ! -f "/workspace/credentials.json" ]; then
    echo "Google Drive sync disabled (no credentials found)"
    echo "Run setup_gdrive_sync.sh for instructions"
    exit 0
fi

# Setup if needed
if [ ! -d "/workspace/gdrive_sync_venv" ]; then
    echo "First run detected, running setup..."
    /scripts/setup_gdrive_sync.sh
fi

# Activate virtual environment
source /workspace/gdrive_sync_venv/bin/activate

# Start the sync service
echo "Starting Google Drive sync service..."
LOG_FILE="/workspace/gdrive_sync_logs/sync_$(date +%Y%m%d_%H%M%S).log"
nohup python /scripts/gdrive_sync.py > "$LOG_FILE" 2>&1 &
SYNC_PID=$!

echo "Google Drive sync started (PID: $SYNC_PID)"
echo "Logs: $LOG_FILE"

# Save PID for later management
echo $SYNC_PID > /tmp/gdrive_sync.pid
