#!/bin/bash
# File: /scripts/status_gdrive_sync.sh
# Status check for Google Drive sync service

if [ -f /tmp/gdrive_sync.pid ]; then
    PID=$(cat /tmp/gdrive_sync.pid)
    if ps -p $PID > /dev/null; then
        echo "✓ Google Drive sync is running (PID: $PID)"

        # Show recent logs
        if [ -d "/workspace/gdrive_sync_logs" ]; then
            LATEST_LOG=$(ls -t /workspace/gdrive_sync_logs/*.log 2>/dev/null | head -1)
            if [ -n "$LATEST_LOG" ]; then
                echo ""
                echo "Recent activity:"
                tail -5 "$LATEST_LOG"
            fi
        fi

        # Show state info
        if [ -f "/workspace/sync_state.json" ]; then
            echo ""
            echo "Sync state:"
            python3 -c "import json; data=json.load(open('/workspace/sync_state.json')); print(f\"  Files uploaded: {len(data.get('uploaded_files', []))}\"); print(f\"  Last updated: {data.get('last_updated', 'Never')}\")"
        fi
    else
        echo "✗ Google Drive sync not running (stale PID)"
    fi
else
    echo "✗ Google Drive sync not running"
fi
