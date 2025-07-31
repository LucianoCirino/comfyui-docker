#!/usr/bin/env bash
set -e

echo "Installing Log Viewer dependencies..."

# Use the system Python to install Flask
python3 -m pip install flask

echo "Log Viewer dependencies installed successfully!"
