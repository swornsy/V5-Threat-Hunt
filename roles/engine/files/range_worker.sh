#!/usr/bin/env bash
# ========================================================================
# UPDATED LINUX JITTER MODEL — RANDOM PARTITION + REMAINING TIME LOGIC
# ========================================================================

CONFIG_PATH="/etc/range_engine/config/campaign_config.json"
MANIFEST_PATH="/etc/range_engine/config/campaign_manifest.json"
STATUS_PILL="/etc/range_engine/config/worker.status"
LOCAL_LOG="/var/log/range_engine_local.log"

if [ ! -f "$CONFIG_PATH" ] || [ ! -f "$MANIFEST_PATH" ]; then
    echo "[ERROR] Missing campaign configuration files."
    exit 1
fi

# Track execution identity markers for telemetry analysis
CURRENT_PID=$$
PARENT_PID=$PPID

DURATION=$(jq -r '.sim_duration' "$CONFIG_PATH")
STEP_COUNT=$(jq -r '.step_count' "$CONFIG_PATH")
CAMPAIGN_START=$(jq -r '.campaign_start' "$CONFIG_PATH")

# ----------------------------------------------------------------------
# Convert duration → seconds
# ----------------------------------------------------------------------
case "$DURATION" in
    "test") TOTAL_SECS=5 ;;
    "30m")  TOTAL_SECS=1800 ;;
    "24h")  TOTAL_SECS=86400 ;;
    "72h")  TOTAL_SECS=259200 ;;
    *)      TOTAL_SECS=1800 ;;
esac

# ----------------------------------------------------------------------
# Compute remaining time window
# ----------------------------------------------------------------------
NOW=$(date +%s)
ELAPSED=$(( NOW - CAMPAIGN_START ))
REMAINING=$(( TOTAL_SECS - ELAPSED ))
[ "$REMAINING" -lt 5 ] && REMAINING=5

# ----------------------------------------------------------------------
# RANDOM PARTITION JITTER GENERATION
# ----------------------------------------------------------------------
JITTER_WINDOWS=()
if [ "$DURATION" = "test" ]; then
    for ((i=0; i<STEP_COUNT; i++)); do
        JITTER_WINDOWS+=("0")
    done
else
    WEIGHTS=()
    WEIGHT_SUM=0
    for ((i=0; i<STEP_COUNT; i++)); do
        W=$(( RANDOM % 1000 + 1 ))
        WEIGHTS+=("$W")
        WEIGHT_SUM=$(( WEIGHT_SUM + W ))
    done

    for W in "${WEIGHTS[@]}"; do
        # Fixed execution math boundary check logic
        if [ "$WEIGHT_SUM" -gt 0 ]; then
            JITTER=$(( (W * REMAINING) / WEIGHT_SUM ))
        else
            JITTER=0
        fi
        JITTER_WINDOWS+=("$JITTER")
    fi
fi

# ----------------------------------------------------------------------
# CHRONOLOGICAL EXECUTION LOOP
# ----------------------------------------------------------------------
for ((i=0; i<STEP_COUNT; i++)); do
    # --------------------------------------------------------------
    # SAFETY GUARD: POISON PILL OVERRIDE (cleanup.yml integration)
    # --------------------------------------------------------------
    if [ -f "$STATUS_PILL" ]; then
        STATUS_VAL=$(cat "$STATUS_PILL" | tr '[:upper:]' '[:lower:]' | xargs)
        if [ "$STATUS_VAL" = "terminate" ]; then
            echo "[Self-Destruct] Poison pill detected. Purging workspace." >> "$LOCAL_LOG"
            rm -rf /etc/range_engine/queue/*
            exit 0
        fi
    fi

    # Extract technique and phase simultaneously to avoid object truncation
    TECHNIQUE=$(jq -r ".[$i].technique" "$MANIFEST_PATH")
    PHASE=$(jq -r ".[$i].phase" "$MANIFEST_PATH")

    # Recalculate runtime remaining constraints dynamically
    LOOP_NOW=$(date +%s)
    if [ $(( LOOP_NOW - CAMPAIGN_START )) -ge $TOTAL_SECS ]; then
        DYNAMIC_JITTER=0
    else
        if [ "$DURATION" = "test" ]; then
            DYNAMIC_JITTER=$(( RANDOM % 3 + 1 ))
        else
            DYNAMIC_JITTER="${JITTER_WINDOWS[$i]}"
        fi
    fi

    sleep "$DYNAMIC_JITTER"

    # --------------------------------------------------------------
    # EXECUTE STEP LOGIC PRIMITIVE HERE
    # --------------------------------------------------------------
    # echo "Executing Phase: $PHASE, Technique: $TECHNIQUE with PID: $CURRENT_PID"
done