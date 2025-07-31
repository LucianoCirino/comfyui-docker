#!/usr/bin/env python3
import os
import time
from flask import Flask, Response, render_template_string
import subprocess
import threading
import queue

app = Flask(__name__)

# HTML template with auto-scrolling and real-time updates
HTML_TEMPLATE = '''
<!DOCTYPE html>
<html>
<head>
    <title>ComfyUI Logs</title>
    <style>
        body {
            background-color: #1e1e1e;
            color: #d4d4d4;
            font-family: 'Consolas', 'Monaco', monospace;
            margin: 0;
            padding: 20px;
        }
        #log-container {
            background-color: #252526;
            border: 1px solid #3e3e42;
            border-radius: 4px;
            padding: 15px;
            height: calc(100vh - 60px);
            overflow-y: auto;
            white-space: pre-wrap;
            word-wrap: break-word;
        }
        .log-line {
            margin: 0;
            line-height: 1.4;
        }
        .error { color: #f48771; }
        .warning { color: #dcdcaa; }
        .info { color: #9cdcfe; }
        .timestamp { color: #858585; }
        h1 {
            color: #cccccc;
            font-size: 20px;
            margin-bottom: 10px;
        }
    </style>
</head>
<body>
    <h1>ComfyUI Logs - Real-time Stream</h1>
    <div id="log-container"></div>

    <script>
        const logContainer = document.getElementById('log-container');
        const eventSource = new EventSource('/stream');

        eventSource.onmessage = function(event) {
            const line = document.createElement('div');
            line.className = 'log-line';

            // Basic syntax highlighting
            let text = event.data;
            if (text.includes('ERROR') || text.includes('Error')) {
                line.className += ' error';
            } else if (text.includes('WARNING') || text.includes('Warning')) {
                line.className += ' warning';
            } else if (text.includes('INFO')) {
                line.className += ' info';
            }

            line.textContent = text;
            logContainer.appendChild(line);

            // Auto-scroll to bottom
            logContainer.scrollTop = logContainer.scrollHeight;

            // Limit number of lines to prevent memory issues
            while (logContainer.children.length > 1000) {
                logContainer.removeChild(logContainer.firstChild);
            }
        };

        eventSource.onerror = function(error) {
            console.error('EventSource failed:', error);
            const line = document.createElement('div');
            line.className = 'log-line error';
            line.textContent = '--- Connection lost, attempting to reconnect... ---';
            logContainer.appendChild(line);
        };
    </script>
</body>
</html>
'''

def tail_file(filename, q):
    """Tail a file and put new lines into a queue"""
    # First, send the last 100 lines to show recent history
    try:
        with open(filename, 'r') as f:
            lines = f.readlines()
            for line in lines[-100:]:
                q.put(line.rstrip())
    except:
        q.put("Waiting for ComfyUI to start...")

    # Then follow the file for new content
    cmd = ['tail', '-f', '-n', '0', filename]
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    for line in iter(process.stdout.readline, ''):
        if line:
            q.put(line.rstrip())

@app.route('/')
def index():
    return render_template_string(HTML_TEMPLATE)

@app.route('/stream')
def stream():
    def generate():
        q = queue.Queue()
        log_file = '/workspace/logs/comfyui.log'

        # Start tailing in a separate thread
        thread = threading.Thread(target=tail_file, args=(log_file, q))
        thread.daemon = True
        thread.start()

        while True:
            try:
                line = q.get(timeout=1)
                yield f"data: {line}\n\n"
            except queue.Empty:
                # Send a heartbeat to keep connection alive
                yield f"data: \n\n"

    return Response(generate(), mimetype="text/event-stream")

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3002, debug=False)
