#!/usr/bin/env python3
"""
Simple Google Drive sync for ComfyUI outputs
Watches the output directory and uploads new images to Google Drive
"""

import os
import json
import time
import logging
from pathlib import Path
from datetime import datetime
from typing import Set

from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

# Configuration
SCOPES = ['https://www.googleapis.com/auth/drive.file']
OUTPUT_DIR = os.getenv('COMFYUI_OUTPUT_DIR', '/workspace/ComfyUI/output')
STATE_FILE = os.getenv('SYNC_STATE_FILE', '/workspace/sync_state.json')
GDRIVE_FOLDER = os.getenv('GDRIVE_FOLDER_NAME', 'ComfyUI-Outputs')
TOKEN_FILE = os.getenv('GDRIVE_TOKEN_FILE', '/workspace/token.json')
CREDS_FILE = os.getenv('GDRIVE_CREDS_FILE', '/workspace/credentials.json')

# File patterns to ignore
IGNORE_PATTERNS = ['.tmp', '.temp', 'Test_', '.json']

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('gdrive_sync')


class ComfyUIOutputHandler(FileSystemEventHandler):
    """Handles file system events for ComfyUI outputs"""

    def __init__(self, uploader):
        self.uploader = uploader
        self.pending_files = {}  # Track files being written

    def on_created(self, event):
        if event.is_directory:
            return

        filepath = event.src_path

        # Check if we should ignore this file
        if self._should_ignore(filepath):
            return

        # Wait a bit for file to be completely written
        self.pending_files[filepath] = time.time()
        logger.info(f"Detected new file: {filepath}")

    def on_modified(self, event):
        if event.is_directory:
            return

        filepath = event.src_path
        if filepath in self.pending_files:
            self.pending_files[filepath] = time.time()

    def process_pending_files(self):
        """Process files that have been stable for 2+ seconds"""
        current_time = time.time()
        ready_files = []

        for filepath, last_modified in list(self.pending_files.items()):
            if current_time - last_modified > 2:  # File stable for 2 seconds
                ready_files.append(filepath)
                del self.pending_files[filepath]

        for filepath in ready_files:
            if os.path.exists(filepath) and os.path.getsize(filepath) > 0:
                self.uploader.upload_file(filepath)

    def _should_ignore(self, filepath):
        """Check if file should be ignored"""
        filename = os.path.basename(filepath)
        return any(pattern in filename for pattern in IGNORE_PATTERNS)


class GDriveUploader:
    """Handles Google Drive uploads and state management"""

    def __init__(self):
        self.service = None
        self.uploaded_files = set()
        self.folder_id = None
        self.load_state()
        self.authenticate()
        self.ensure_folder()

    def authenticate(self):
        """Authenticate with Google Drive"""
        creds = None

        # Load existing token
        if os.path.exists(TOKEN_FILE):
            creds = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)

        # If there are no (valid) credentials available, let the user log in
        if not creds or not creds.valid:
            if creds and creds.expired and creds.refresh_token:
                creds.refresh(Request())
            else:
                if not os.path.exists(CREDS_FILE):
                    logger.error(f"Credentials file not found: {CREDS_FILE}")
                    logger.info("Please download OAuth2 credentials from Google Cloud Console")
                    logger.info("1. Go to https://console.cloud.google.com/")
                    logger.info("2. Create a new project or select existing")
                    logger.info("3. Enable Google Drive API")
                    logger.info("4. Create OAuth 2.0 credentials (Desktop type)")
                    logger.info("5. Download and save as credentials.json")
                    raise FileNotFoundError(f"Missing {CREDS_FILE}")

                flow = InstalledAppFlow.from_client_secrets_file(CREDS_FILE, SCOPES)
                # For headless/Docker environments, use console flow
                creds = flow.run_console()

            # Save the credentials for the next run
            with open(TOKEN_FILE, 'w') as token:
                token.write(creds.to_json())

        self.service = build('drive', 'v3', credentials=creds)
        logger.info("Successfully authenticated with Google Drive")

    def ensure_folder(self):
        """Ensure the upload folder exists in Google Drive"""
        # Search for existing folder
        results = self.service.files().list(
            q=f"name='{GDRIVE_FOLDER}' and mimeType='application/vnd.google-apps.folder' and trashed=false",
            spaces='drive',
            fields='files(id, name)'
        ).execute()

        folders = results.get('files', [])

        if folders:
            self.folder_id = folders[0]['id']
            logger.info(f"Using existing folder: {GDRIVE_FOLDER} (ID: {self.folder_id})")
        else:
            # Create folder
            file_metadata = {
                'name': GDRIVE_FOLDER,
                'mimeType': 'application/vnd.google-apps.folder'
            }
            folder = self.service.files().create(
                body=file_metadata,
                fields='id'
            ).execute()
            self.folder_id = folder.get('id')
            logger.info(f"Created new folder: {GDRIVE_FOLDER} (ID: {self.folder_id})")

    def upload_file(self, filepath):
        """Upload a file to Google Drive"""
        filename = os.path.basename(filepath)

        # Check if already uploaded
        if filename in self.uploaded_files:
            logger.debug(f"File already uploaded: {filename}")
            return

        try:
            # Prepare file metadata
            file_metadata = {
                'name': filename,
                'parents': [self.folder_id]
            }

            # Determine MIME type
            mime_type = 'image/png' if filepath.endswith('.png') else 'image/jpeg'

            media = MediaFileUpload(
                filepath,
                mimetype=mime_type,
                resumable=True
            )

            # Upload file
            file = self.service.files().create(
                body=file_metadata,
                media_body=media,
                fields='id'
            ).execute()

            # Record upload
            self.uploaded_files.add(filename)
            self.save_state()

            logger.info(f"Successfully uploaded: {filename} (ID: {file.get('id')})")

        except Exception as e:
            logger.error(f"Failed to upload {filename}: {e}")

    def load_state(self):
        """Load sync state from file"""
        if os.path.exists(STATE_FILE):
            try:
                with open(STATE_FILE, 'r') as f:
                    data = json.load(f)
                    self.uploaded_files = set(data.get('uploaded_files', []))
                    logger.info(f"Loaded state: {len(self.uploaded_files)} files already uploaded")
            except Exception as e:
                logger.error(f"Failed to load state: {e}")
                self.uploaded_files = set()
        else:
            self.uploaded_files = set()

    def save_state(self):
        """Save sync state to file"""
        try:
            with open(STATE_FILE, 'w') as f:
                json.dump({
                    'uploaded_files': list(self.uploaded_files),
                    'last_updated': datetime.now().isoformat()
                }, f, indent=2)
        except Exception as e:
            logger.error(f"Failed to save state: {e}")


def main():
    """Main entry point"""
    logger.info("Starting ComfyUI Google Drive Sync")
    logger.info(f"Watching directory: {OUTPUT_DIR}")

    # Create output directory if it doesn't exist
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Initialize uploader
    try:
        uploader = GDriveUploader()
    except Exception as e:
        logger.error(f"Failed to initialize uploader: {e}")
        return

    # Scan existing files (optional - uncomment to upload existing files)
    # logger.info("Scanning existing files...")
    # for root, dirs, files in os.walk(OUTPUT_DIR):
    #     for file in files:
    #         filepath = os.path.join(root, file)
    #         if not any(pattern in file for pattern in IGNORE_PATTERNS):
    #             uploader.upload_file(filepath)

    # Set up file system observer
    event_handler = ComfyUIOutputHandler(uploader)
    observer = Observer()
    observer.schedule(event_handler, OUTPUT_DIR, recursive=True)
    observer.start()

    logger.info("Sync service started. Watching for new files...")

    try:
        while True:
            time.sleep(1)
            event_handler.process_pending_files()
    except KeyboardInterrupt:
        observer.stop()
        logger.info("Sync service stopped")

    observer.join()


if __name__ == '__main__':
    main()
