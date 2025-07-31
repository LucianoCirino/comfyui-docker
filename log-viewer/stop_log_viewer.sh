#!/usr/bin/env bash

echo "Stopping ComfyUI Log Viewer..."

# Find and kill the log viewer process
# Using pkill with the full path to be more specific
pkill -f "/workspace/ComfyUI/venv/bin/python.*log_streamer.py"

if [ $? -eq 0 ]; then
    echo "Log viewer stopped successfully"
else
    # Try again with a broader pattern if the first attempt failed
    pkill -f "log_streamer.py"
    if [ $? -eq 0 ]; then
        echo "Log viewer stopped successfully"
    else
        echo "Log viewer was not running"
    fi
fi
