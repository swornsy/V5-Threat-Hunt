#!/bin/bash
# score_hunt.sh - Interactive Verification Engine

GROUND_TRUTH="/tmp/adversary_report.txt"
SIEM_API="https://siem.sorensen.test/api/alerts"

echo "=========================================================="
echo "      Adversary Simulation Range Validation Engine        "
echo "=========================================================="

while IFS='|' read -r actor host timestamp phase action technique; do
    # Trim Whitespace values
    tech_id=$(echo "$technique" | xargs)
    target_node=$(echo "$host" | xargs)
    
    echo -n "[*] Auditing SIEM Alerts for Technique $tech_id on $target_node... "
    
    # Query your SIEM API to confirm if the team successfully flagged the technique
    RESPONSE=$(curl -s -k -u "admin:password" "$SIEM_API?q=technique:\"$tech_id\"+AND+host:\"$target_node\"")
    
    if [[ "$RESPONSE" == *"total\":0"* ]]; then
        echo "❌ MISSING (Blindspot Detected)"
    else
        echo "✅ DETECTED"
    fi
done < "$GROUND_TRUTH"
