#!/bin/bash
# File: drive-sync/status.sh (Optional - for checking status)
# Status check for Google Drive sync service

if [ -f /tmp/drive-sync.pid ]; then
    PID=$(cat /tmp/drive-sync.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "✓ Drive sync is running (PID: $PID)"

        # Show recent log entries
        LOG_DIR="/workspace/logs/drive-sync"
        if [ -d "$LOG_DIR" ]; then
            LATEST_LOG=$(ls -t "$LOG_DIR"/*.log 2>/dev/null | head -1)
            if [ -n "$LATEST_LOG" ]; then
                echo ""
                echo "Recent activity (last 5 lines):"
                tail -5 "$LATEST_LOG"
            fi
        fi

        # Show sync statistics
        if [ -f "/workspace/sync_state.json" ]; then
            echo ""
            echo "Sync statistics:"
            python3 -c "
import json
try:
    with open('/workspace/sync_state.json') as f:
        data = json.load(f)
        print(f\"  Files uploaded: {len(data.get('uploaded_files', []))}\")
        print(f\"  Last updated: {data.get('last_updated', 'Never')}\")
except:
    print('  Unable to read sync state')
"
        fi
    else
        echo "✗ Drive sync is not running (stale PID: $PID)"
        rm /tmp/drive-sync.pid
    fi
else
    echo "✗ Drive sync is not running"
fi
