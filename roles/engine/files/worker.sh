#!/usr/bin/env bash

# ========================================================================

# CYBER RANGE PERSISTENT WORKER - LINUX ENGINE (worker.sh)

# ========================================================================

WORK_DIR="/tmp/.range_engine"

QUEUE_FILE="$WORK_DIR/incoming.sh"

OUTPUT_FILE="$WORK_DIR/result.txt"

STATUS_FILE="$WORK_DIR/worker.status"


mkdir -p "$WORK_DIR"

echo "running" > "$STATUS_FILE"


while true; do

    if [ -f "$QUEUE_FILE" ]; then

        # Execute natively in the current shell context to keep the PID tree clean

        chmod +x "$QUEUE_FILE"

        source "$QUEUE_FILE" > "$OUTPUT_FILE" 2>&1

        rm -f "$QUEUE_FILE"

    fi


    # Poison pill self-destruct check

    if [ -f "$STATUS_FILE" ] && [ "$(cat "$STATUS_FILE" | tr -d '[:space:]')" = "terminate" ]; then

        rm -rf "$WORK_DIR"

        exit 0

    fi

    sleep 1

done
