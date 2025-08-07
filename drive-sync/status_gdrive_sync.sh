#!/usr/bin/env bash
# File: drive-sync/status_gdrive_sync.sh
# Status check for Google Drive sync service

if pgrep -f "gdrive_sync.py" > /dev/null; then
    PID=$(pgrep -f "gdrive_sync.py")
    echo "✓ Drive sync is running (PID: $PID)"

    # Show recent log entries
    if [ -f "/workspace/logs/drive-sync/sync.log" ]; then
        echo ""
        echo "Recent activity (last 5 lines):"
        tail -5 "/workspace/logs/drive-sync/sync.log"
    fi

    # Show sync statistics
    if [ -f "/workspace/drive-sync-state.json" ]; then
        echo ""
        echo "Sync statistics:"
        /drive-sync/venv/bin/python -c "
import json
try:
    with open('/workspace/drive-sync-state.json') as f:
        data = json.load(f)
        print(f\"  Files uploaded: {len(data.get('uploaded_files', []))}\")
        print(f\"  Last updated: {data.get('last_updated', 'Never')}\")
except:
    print('  Unable to read sync state')
"
    fi
else
    echo "✗ Drive sync is not running"
fi
