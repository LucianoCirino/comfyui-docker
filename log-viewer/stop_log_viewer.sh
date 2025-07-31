#!/usr/bin/env bash

echo "Stopping ComfyUI Log Viewer..."

# Find and kill the log viewer process
pkill -f "log_streamer.py"

if [ $? -eq 0 ]; then
    echo "Log viewer stopped successfully"
else
    echo "Log viewer was not running"
fi
