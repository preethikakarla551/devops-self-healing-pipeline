#!/usr/bin/env bash

TARGET_URL="http://127.0.0.1:5000/health"
LOG_FILE="/var/log/app_health.log"
CONTAINER_NAME="web_app"

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET_URL" || true)

if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - OK: Application operational." >> "$LOG_FILE"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ALERT: Service down (HTTP $HTTP_STATUS). Triggering recovery..." >> "$LOG_FILE"
    docker restart "$CONTAINER_NAME" >> "$LOG_FILE" 2>&1
    echo "$(date '+%Y-%m-%d %H:%M:%S') - RECOVERY: Container $CONTAINER_NAME restarted." >> "$LOG_FILE"
fi
