#!/bin/bash

###################################################################
# Sends Telegram notifications using the webhook configuration
# defined on the Proxmox node for Telegram-based notifications.
###################################################################

# -----------------------------
# Configuración
# -----------------------------
PROXMOX_SECRET_FILE="/etc/pve/priv/notifications.cfg"   # Proxmox webhooks secret file
TARGET_WEBHOOK="TelegramBot"                            # Webhook selected
LOG_FILE="/var/log/telegram_notifier.log"               # File to save logs
DATE_FMT="+%Y-%m-%d %H:%M:%S"                           # Date format for log

# -----------------------------
# Logging function
# -----------------------------
log() {
    local TYPE="$1"
    local MSG="$2"
    echo "$(date "$DATE_FMT") [$TYPE] $MSG" | tee -a "$LOG_FILE"
}

# -----------------------------
# Validate required parameter
# -----------------------------
if [ -z "$1" ]; then
    log "ERROR" "No message parameter provided."
    echo "Usage: $0 \"Message to send\"" >&2
    exit 1
fi

MESSAGE="$*"

# -----------------------------
# Extract base64 values from secret file
# -----------------------------
BOT_ID_B64=$(awk -v webhook="$TARGET_WEBHOOK" '
    $1=="webhook:" && $2==webhook {inblock=1; next}
    $1=="webhook:" {inblock=0}
    inblock && $0 ~ /name=bot_id/ {
        val=$0
        sub(/.*value=/,"",val)
        print val
    }
' "$PROXMOX_SECRET_FILE")

CHAT_ID_B64=$(awk -v webhook="$TARGET_WEBHOOK" '
    $1=="webhook:" && $2==webhook {inblock=1; next}
    $1=="webhook:" {inblock=0}
    inblock && $0 ~ /name=chat_id/ {
        val=$0
        sub(/.*value=/,"",val)
        print val
    }
' "$PROXMOX_SECRET_FILE")

# -----------------------------
# Validate extraction
# -----------------------------
if [ -z "$BOT_ID_B64" ] || [ -z "$CHAT_ID_B64" ]; then
    log "ERROR" "Could not read bot_id or chat_id (base64) for webhook $TARGET_WEBHOOK"
    exit 1
fi

# -----------------------------
# Decode base64 values
# -----------------------------
BOT_ID=$(echo "$BOT_ID_B64" | base64 -d 2>/dev/null)
CHAT_ID=$(echo "$CHAT_ID_B64" | base64 -d 2>/dev/null)

if [ -z "$BOT_ID" ] || [ -z "$CHAT_ID" ]; then
    log "ERROR" "Failed to decode base64 bot_id or chat_id"
    exit 1
fi

# -----------------------------
# Send message (form-urlencoded)
# -----------------------------
HTTP_CODE=$(curl -s -o /tmp/telegram_response.txt -w "%{http_code}" \
    -X POST "https://api.telegram.org/bot${BOT_ID}/sendMessage" \
    --data-urlencode "chat_id=${CHAT_ID}" \
    --data-urlencode "text=${MESSAGE}" \
    --data-urlencode "parse_mode=Markdown")

# -----------------------------
# Check HTTP response
# -----------------------------
if [ "$HTTP_CODE" -eq 200 ]; then
    log "INFO" "Message successfully sent: $MESSAGE"
else
    RESPONSE=$(cat /tmp/telegram_response.txt)
    log "ERROR" "Failed to send message. HTTP: $HTTP_CODE | Response: $RESPONSE"
fi

rm -f /tmp/telegram_response.txt
