#!/usr/bin/env bash
set -e

echo "Installing Log Viewer with dedicated venv..."

# Create a dedicated venv for log viewer
python3 -m venv /log-viewer/venv

# Activate the venv and install Flask
source /log-viewer/venv/bin/activate
pip install --upgrade pip
pip install flask
deactivate

echo "Log Viewer installed successfully with its own venv!"
