#!/bin/bash

# Resolve script directory to load relative files safely
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load configuration from .env if present
if [ -f "${SCRIPT_DIR}/.env" ]; then
    # shellcheck disable=SC1090
    source "${SCRIPT_DIR}/.env"
fi

# Configuration defaults
STATUS_FILE="${STATUS_FILE:-/tmp/office_status.txt}"

# Verify required configuration
if [ -z "$IP" ] || [ -z "$TOKEN" ] || [ -z "$CHAT_ID" ]; then
    echo "Error: IP, TOKEN, and CHAT_ID must be configured in ${SCRIPT_DIR}/.env or environment." >&2
    exit 1
fi

# Function to send Telegram alert
send_telegram() {
    local message="$1"
    curl -s --fail -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
         -d "chat_id=${CHAT_ID}" \
         --data-urlencode "text=${message}" > /dev/null
}

# Check for manual test mode
if [ "$1" = "--test" ] || [ "$1" = "-t" ]; then
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')
    echo "Running manual test against ${IP}..."
    if ping -c 3 -W 2 -w 10 "$IP" > /dev/null 2>&1; then
        echo "Ping succeeded. Sending confirmation message to Telegram..."
        if send_telegram "🤖 TEST: Office Internet (${IP}) is ONLINE and Telegram alerting is working! [${TIMESTAMP}]"; then
            echo "Test message delivered successfully to Telegram!"
        else
            echo "Error: Failed to deliver message to Telegram."
            exit 1
        fi
    else
        echo "Ping failed. Sending alert test message to Telegram..."
        if send_telegram "🤖 TEST ALERT: Office Internet (${IP}) is UNREACHABLE! [${TIMESTAMP}]"; then
            echo "Test alert delivered successfully to Telegram!"
        else
            echo "Error: Failed to deliver message to Telegram."
            exit 1
        fi
    fi
    exit 0
fi

# Ping the office IP 3 times with a 2-second timeout per packet (max 10s deadline)
if ! ping -c 3 -W 2 -w 10 "$IP" > /dev/null 2>&1; then
    # Ping failed (Office DOWN)
    if [ ! -f "$STATUS_FILE" ]; then
        TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')
        if send_telegram "🚨 ALARM: Office Internet (${IP}) is DOWN! [${TIMESTAMP}]"; then
            touch "$STATUS_FILE"
        fi
    fi
else
    # Ping succeeded (Office ONLINE)
    if [ -f "$STATUS_FILE" ]; then
        TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')
        if send_telegram "✅ RECOVERED: Office Internet (${IP}) is BACK ONLINE! [${TIMESTAMP}]"; then
            rm -f "$STATUS_FILE"
        fi
    fi
fi
