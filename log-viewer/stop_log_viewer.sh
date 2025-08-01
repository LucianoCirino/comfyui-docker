
#!/usr/bin/env bash

echo "Stopping ComfyUI Log Viewer..."

# Find and kill the log viewer process (now using the venv python)
pkill -f "/log-viewer/venv/bin/python.*log_streamer.py"

if [ $? -eq 0 ]; then
    echo "Log viewer stopped successfully"
else
    echo "Log viewer was not running"
fi
