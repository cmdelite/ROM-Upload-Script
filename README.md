# ROM Upload Automation Script

Created by @cmdelite - Special thanks to DeepSeek Chat for development assistance

This script automatically finds, uploads, and shares ROM files via Google Drive with Telegram notifications.

# Features:
- Finds the latest ROM file in specified directory
- Uploads to Google Drive with progress monitoring
- Sends status notifications to main Telegram channel
- Sends download links to separate download channel
- Maintains detailed logs of all operations

# Setup Instructions:

# 1. Prerequisites:
- Linux system with bash
- gdrive CLI tool installed and configured
- curl installed

# 2. Configuration:
Edit these variables in the script:

Telegram Configuration
TG_BOT_TOKEN="your_bot_token_here"
TG_MAIN_CHAT_ID="your_main_chat_id" 
TG_DOWNLOAD_CHAT_ID="your_download_chat_id"

Google Drive Configuration
GDRIVE_FOLDER_ID="your_folder_id"

# 3. ROM Customization:
To use with different ROMs, modify the find command:

For Axion ROM (default):
find "$OUT" -type f -iname "axion*.zip"

For other ROMs (replace 'lineage' with your ROM name):
find "$OUT" -type f -iname "lineage*.zip"

# Usage:
chmod +x rom_upload.sh
./rom_upload.sh

# How It Works:
1. Searches for newest ROM file
2. Uploads to Google Drive
3. Sends notifications to separate channels
4. Maintains detailed log file

# Telegram Channel Setup:
- Main Channel: For script status notifications
- Download Channel: Only receives download links
(Get chat IDs using @RawDataBot)

# Troubleshooting:
- Permission denied: Run chmod +x rom_upload.sh
- gdrive not found: Install from gdrive GitHub
- Telegram messages not sending: Verify bot token and chat IDs
- Link Private: Change permissions manually (drive.google.com)

License: MIT License

Credits:
- Script developed by @cmdelite]
- With significant contributions from DeepSeek Chat AI assistant
- Inspired by community ROM development workflows

Pro Tip: Add to your build process to automatically share builds!
