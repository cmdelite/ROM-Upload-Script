#!/bin/bash

# ========== Configuration ==========
TG_BOT_TOKEN="your_telegram_bot_token"
TG_MAIN_CHAT_ID="your_telegram_main_chat_id"       # Main notifications channel
TG_DOWNLOAD_CHAT_ID="your_telegram_download_chat_id"   # Separate channel for download info
GDRIVE_FOLDER_ID="your_gdrive_folder_id"

# Initialize log file
LOG_FILE="rom_upload_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# ========== Telegram Functions ==========
send_telegram() {
  local chat_id="$1"
  local message="$2"
  
  # URL encode special characters but preserve the URL structure
  local encoded_message=$(echo "$message" | sed \
    -e 's/%/%25/g' \
    -e 's/&/%26/g' \
    -e 's/+/%2b/g' \
    -e 's/ /%20/g' \
    -e 's/"/%22/g' \
    -e "s/'/%27/g" \
    -e 's/#/%23/g' \
    -e 's/(/%28/g' \
    -e 's/)/%29/g')

  echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] Sending to Telegram (${chat_id}): ${message}"
  curl -s -X POST "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${chat_id}" \
    -d "text=${encoded_message}" \
    -d "disable_web_page_preview=true" >> "$LOG_FILE" 2>&1
}

send_log_file() {
  echo -e "\n=== Sending Log File ==="
  if [[ -f "$LOG_FILE" ]]; then
    curl -s -X POST "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendDocument" \
      -F "chat_id=${TG_MAIN_CHAT_ID}" \
      -F "document=@${LOG_FILE}" \
      -F "caption=Upload Log - $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE" 2>&1
  fi
}

# ========== Main Upload Function ==========
upload_rom() {
  echo "=== Starting ROM Upload ==="
  send_telegram "$TG_MAIN_CHAT_ID" "🚀 Starting ROM upload process..."

  # Find latest ROM file
  echo -e "\n🔍 Searching for ROM file..."
  local rom_file=$(find "$OUT" -type f -iname "axion*.zip" -printf "%T@ %p\n" 2>/dev/null | 
                  sort -n | tail -1 | cut -d' ' -f2-)
  
  if [[ -z "$rom_file" ]]; then
    send_telegram "$TG_MAIN_CHAT_ID" "❌ Error: No ROM file found in ${OUT}"
    send_log_file
    exit 1
  fi

  local file_name=$(basename "$rom_file")
  local file_size=$(du -h "$rom_file" | cut -f1)
  
  echo -e "\n✅ Found ROM file: ${file_name} (${file_size})"
  send_telegram "$TG_MAIN_CHAT_ID" "✅ Found: ${file_name} (${file_size})"
  send_telegram "$TG_MAIN_CHAT_ID" "⬆️ Starting upload to Google Drive..."

  # Upload to Google Drive
  echo -e "\n=== Uploading ==="
  local upload_output=$(gdrive files upload --parent "$GDRIVE_FOLDER_ID" "$rom_file" 2>&1)
  echo "$upload_output"
  
  # Extract file ID
  local file_id=$(echo "$upload_output" | grep -oP 'Uploaded \K[^ ]+' || 
                 echo "$upload_output" | grep -oP 'Id: \K[^ ]+')
  
  if [[ -z "$file_id" ]]; then
    send_telegram "$TG_MAIN_CHAT_ID" "❌ Error: Failed to extract file ID"
    send_log_file
    exit 1
  fi

  # Generate and send download link
  local download_link="https://drive.google.com/uc?export=download&id=${file_id}"
  
  # Format message with proper line breaks
  local download_msg=$(printf "📌 ROM Download Ready!\n\nFile: %s\nSize: %s\nDownload: %s" \
    "$file_name" "$file_size" "$download_link")

  send_telegram "$TG_DOWNLOAD_CHAT_ID" "$download_msg"
  send_telegram "$TG_MAIN_CHAT_ID" "✅ Upload completed successfully!"
  echo -e "\n=== Done ==="
}

# ========== Main Execution ==========
if [[ -z "$OUT" ]]; then
  echo "❌ Error: OUT environment variable not set"
  exit 1
fi

upload_rom
send_log_file
