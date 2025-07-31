#!/usr/bin/env bash

echo "Starting ComfyUI Log Viewer..."

# Create logs directory if it doesn't exist
mkdir -p /workspace/logs

# Check if already running
if pgrep -f "log_streamer.py" > /dev/null; then
    echo "Log viewer is already running"
    exit 0
fi

# Start the log viewer service
cd /log-viewer
python3 log_streamer.py > /workspace/logs/log_viewer.log 2>&1 &

echo "ComfyUI Log Viewer started on port 3002"
echo "Log file: /workspace/logs/log_viewer.log"
