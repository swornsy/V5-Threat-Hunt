#!/bin/bash
# ========================================================================
# NESTED DICTIONARY CYBER RANGE SIMULATION LAUNCHER (YAML-MATCHED)
# ========================================================================

clear
echo "========================================================================"
echo "    V5 THREAT HUNT CYBER RANGE - ADVERSARY SIMULATION LAUNCHER"
echo "========================================================================"
echo ""

CATALOG="/home/ubuntu/V5-Threat-Hunt/vars/apt_catalog.yml"

if [ ! -f "$CATALOG" ]; then
    echo "[ERROR] APT Catalog database not found at $CATALOG"
    exit 1
fi

# ------------------------------------------------------------------------
# STEP 1: DYNAMIC COUNTRY SELECTION VIA PYTHON
# ------------------------------------------------------------------------
echo "[*] Querying Threat Intelligence Regional Matrix..."

active_regions_str=$(python3 -c "
import yaml, sys
try:
    with open('$CATALOG', 'r') as f:
        data = yaml.load(f, Loader=yaml.SafeLoader)
    catalog_root = data.get('apt_catalog', {})
    countries = list(catalog_root.keys())
    print(','.join(countries))
except Exception as e:
    sys.exit(1)
")

IFS=',' read -r -a countries <<< "$active_regions_str"

if [ ${#countries[@]} -eq 0 ]; then
    countries=("China" "Russia" "Iran" "North Korea")
fi

echo "Select Target Threat Actor Country of Origin:"
echo "------------------------------------------------------------------------"
for i in "${!countries[@]}"; do
    echo "$((i+1))) ${countries[$i]}"
done
echo "------------------------------------------------------------------------"
read -p "Choose a region (1-${#countries[@]}): " country_choice

if ! [[ "$country_choice" =~ ^[0-9]+$ ]] || [ "$country_choice" -le 0 ] || [ "$country_choice" -gt "${#countries[@]}" ]; then
    selected_country="${countries}"
else
    selected_country="${countries[$((country_choice-1))]}"
fi

# ------------------------------------------------------------------------
# STEP 2: DYNAMIC ACTOR SELECTION FOR SPECIFIC COUNTRY
# ------------------------------------------------------------------------
echo ""
echo "[*] Querying threat intelligence footprints for [ $selected_country ]..."
echo "------------------------------------------------------------------------"

mapfile -t actors < <(python3 -c "
import yaml
with open('$CATALOG', 'r') as f:
    data = yaml.load(f, Loader=yaml.SafeLoader)

catalog_root = data.get('apt_catalog', {})
actors_list = catalog_root.get('$selected_country', [])

for actor in actors_list:
    if isinstance(actor, dict):
        name = actor.get('name', 'Unknown')
        aid = actor.get('id', 'G0000')
        print(f'{name}|{aid}')
")

if [ ${#actors[@]} -eq 0 ]; then
    if [ "$selected_country" == "China" ]; then
        actors=("admin@338|G0018" "Aoqin Dragon|G1007" "APT1|G0006")
    else
        actors=("Default Actor|G0000")
    fi
fi

for i in "${!actors[@]}"; do
    actor_name=$(echo "${actors[$i]}" | cut -d'|' -f1)
    actor_id=$(echo "${actors[$i]}" | cut -d'|' -f2)
    echo "$((i+1))) $actor_name ($actor_id)"
done

echo "------------------------------------------------------------------------"
read -p "Select threat profile to emulate (1-${#actors[@]}): " actor_choice

if ! [[ "$actor_choice" =~ ^[0-9]+$ ]] || [ "$actor_choice" -le 0 ] || [ "$actor_choice" -gt "${#actors[@]}" ]; then
    target_actor="${actors}"
else
    target_actor="${actors[$((actor_choice-1))]}"
fi

actor_name=$(echo "$target_actor" | cut -d'|' -f1)
actor_id=$(echo "$target_actor" | cut -d'|' -f2)

# ------------------------------------------------------------------------
# STEP 3: TEMPORAL BEHAVIOR PROFILE SELECTION
# ------------------------------------------------------------------------
echo ""
echo "[*] Select Attack Pacing & Mode:"
echo "------------------------------------------------------------------------"
echo "1) Chronological Jitter (Temporal Mode - Uses Sequencing Engine)"
echo "2) Flat Matrix Fallback (Executes all techniques simultaneously)"
echo "------------------------------------------------------------------------"
read -p "Choose an option (1-2): " mode_choice

if [ "$mode_choice" -eq 1 ]; then
    attack_mode="temporal"
else
    attack_mode="flat"
fi

# ------------------------------------------------------------------------
# STEP 4: ATTACK PROFILE BEHAVIOR NOISE LEVEL
# ------------------------------------------------------------------------
echo ""
echo "[*] Select Attack Noise Profile:"
echo "------------------------------------------------------------------------"
echo "1) Mixed    (Standard randomized timing buffers)"
echo "2) Noisy    (Rapid technique execution - High EDR visibility)"
echo "3) Medium   (Moderate pacing delay blocks)"
echo "4) Stealthy (Long dwell times - Evades basic heuristic tracking)"
echo "------------------------------------------------------------------------"
read -p "Choose an option (1-4): " behavior_choice

case $behavior_choice in
    1) attack_behaviour="mixed" ;;
    2) attack_behaviour="noisy" ;;
    3) attack_behaviour="medium" ;;
    4) attack_behaviour="stealthy" ;;
    *) attack_behaviour="mixed" ;;
esac

# ------------------------------------------------------------------------
# STEP 5: CORE PLAYBOOK EXECUTION PIPELINE
# ------------------------------------------------------------------------
echo ""
echo "[+] Configuration Matrix Selected:"
echo "    - Origin Region       : $selected_country"
echo "    - Target Threat Actor : $actor_name ($actor_id)"
echo "    - Orchestration Mode  : $attack_mode"
echo "    - Pacing Behavior     : $attack_behaviour"
echo "------------------------------------------------------------------------"
echo "[+] Cleaning temporary environmental tracks..."

rm -f runtime_vars.yml

echo "[*] Handing configuration targets off to Ansible Automation Engine..."
echo ""

ansible-playbook -i inventory/hosts.ini site.yml -e "
selected_actor_name='${actor_name}' \
selected_actor_id='${actor_id}' \
attack_mode='${attack_mode}' \
attack_behaviour='${attack_behaviour}' \
attack_duration='60'
"
EOF
