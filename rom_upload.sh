#!/bin/bash

# ========== Configuration ==========
TG_BOT_TOKEN="your_telegram_bot_token"
TG_MAIN_CHAT_ID="your_telegram_main_chat_id"       # Main notifications channel
TG_DOWNLOAD_CHAT_ID="your_telegram_download_chat_id"   # Separate channel for download info
GDRIVE_FOLDER_ID="your_gdrive_folder_id"

# Initialize log file
LOG_FILE="rom_upload_$(date +%Y%m%d_%H%M%S).log"
echo "=== ROM Upload Script ===" | tee "$LOG_FILE"
echo "Start: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"

# ========== Telegram Functions ==========
send_telegram() {
  local chat_id="$1"
  local message="$2"
  
  echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] Telegram to $chat_id: $message" >> "$LOG_FILE"
  echo -e "[Telegram]: $message"  # Terminal output
  
  curl -s -X POST "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage" \
    -d "chat_id=$chat_id" \
    -d "text=$message" >> "$LOG_FILE" 2>&1
}

send_telegram_file() {
  local chat_id="$1"
  echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] Sending log to $chat_id" >> "$LOG_FILE"
  
  curl -s -X POST "https://api.telegram.org/bot$TG_BOT_TOKEN/sendDocument" \
    -F "chat_id=$chat_id" \
    -F "document=@$LOG_FILE" \
    -F "caption=ROM Upload Log - $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE" 2>&1
}

# ========== Main Function ==========
upload_rom() {
  # 1. Find ROM file
  echo -e "\n=== Searching ROM ===" | tee -a "$LOG_FILE"
  send_telegram "$TG_MAIN_CHAT_ID" "🔍 Searching for ROM file..."
  
  local rom_file=$(find "$OUT" -type f -iname "axion*.zip" -printf "%T@ %p\n" 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
  
  [[ -z "$rom_file" ]] && {
    send_telegram "$TG_MAIN_CHAT_ID" "❌ Error: No ROM file found"
    exit 1
  }

  local file_name=$(basename "$rom_file")
  local file_size=$(du -h "$rom_file" | cut -f1)
  
  # 2. Start upload
  echo -e "\n✅ Found: $file_name ($file_size)" | tee -a "$LOG_FILE"
  send_telegram "$TG_MAIN_CHAT_ID" "✅ Found: $file_name ($file_size)"
  send_telegram "$TG_MAIN_CHAT_ID" "⬆️ Uploading to Google Drive..."

  # 3. Upload to Google Drive
  echo -e "\n=== Uploading ===" | tee -a "$LOG_FILE"
  local upload_log=$(gdrive files upload --parent "$GDRIVE_FOLDER_ID" "$rom_file" 2>&1)
  echo "$upload_log" | tee -a "$LOG_FILE"
  
  # 4. Get download link
  local file_id=$(echo "$upload_log" | grep -oP 'Uploaded \K[^ ]+' || echo "$upload_log" | grep -oP 'Id: \K[^ ]+')
  [[ -z "$file_id" ]] && {
    send_telegram "$TG_MAIN_CHAT_ID" "❌ Error: Failed to get download link"
    exit 1
  }

  # 5. Send download info to DOWNLOAD channel only
  local download_url="https://drive.google.com/uc?export=download&id=$file_id"
  local download_msg="📌 New ROM Available!
  
Filename: $file_name
Size: $file_size
Uploaded: $(date '+%Y-%m-%d %H:%M:%S')
Download: $download_url"
  
  echo -e "\n=== Download Info ===" | tee -a "$LOG_FILE"
  echo "$download_msg" | tee -a "$LOG_FILE"
  send_telegram "$TG_DOWNLOAD_CHAT_ID" "$download_msg"
  
  # 6. Completion (to main channel)
  send_telegram "$TG_MAIN_CHAT_ID" "✅ Upload completed successfully!"
  echo -e "\n✅ Done!" | tee -a "$LOG_FILE"
}

# ========== Execution ==========
clear
echo -e "=== ROM Upload Starting ==="
send_telegram "$TG_MAIN_CHAT_ID" "🚀 ROM upload process started..."
upload_rom

# Send final log to main channel
send_telegram "$TG_MAIN_CHAT_ID" "📁 Sending complete log..."
send_telegram_file "$TG_MAIN_CHAT_ID"

echo -e "\n=== Clean Up ==="
rm -f "$LOG_FILE"
echo -e "Script completed!\n"
