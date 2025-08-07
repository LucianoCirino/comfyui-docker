#!/bin/bash
# File: drive-sync/stop.sh
# Stop script for Google Drive sync service (follows log-viewer/stop.sh pattern)

if [ -f /tmp/drive-sync.pid ]; then
    PID=$(cat /tmp/drive-sync.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "Stopping drive sync service (PID: $PID)..."
        kill $PID

        # Wait for process to stop
        sleep 2

        if ps -p $PID > /dev/null 2>&1; then
            echo "Process didn't stop gracefully, forcing..."
            kill -9 $PID
        fi

        rm /tmp/drive-sync.pid
        echo "Drive sync service stopped"
    else
        echo "Drive sync process not found (PID: $PID)"
        rm /tmp/drive-sync.pid
    fi
else
    echo "Drive sync service is not running (no PID file found)"
fi

