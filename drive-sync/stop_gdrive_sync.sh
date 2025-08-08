#!/usr/bin/env bash
# File: drive-sync/stop_gdrive_sync.sh
# Stop script for Google Drive sync service

echo "Stopping Google Drive sync..."

# Find and kill the process
if pgrep -f "gdrive_sync.py" > /dev/null; then
    pkill -f "gdrive_sync.py"
    echo "Drive sync stopped"
else
    echo "Drive sync is not running"
fi

