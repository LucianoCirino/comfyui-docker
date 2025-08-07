#!/bin/bash
# File: /scripts/stop_gdrive_sync.sh
# Stop script for Google Drive sync service

if [ -f /tmp/gdrive_sync.pid ]; then
    PID=$(cat /tmp/gdrive_sync.pid)
    if ps -p $PID > /dev/null; then
        echo "Stopping Google Drive sync (PID: $PID)..."
        kill $PID
        rm /tmp/gdrive_sync.pid
        echo "Google Drive sync stopped"
    else
        echo "Google Drive sync not running (stale PID)"
        rm /tmp/gdrive_sync.pid
    fi
else
    echo "Google Drive sync not running (no PID file)"
fi

