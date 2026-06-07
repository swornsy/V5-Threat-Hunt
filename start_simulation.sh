#!/bin/bash

# =======================================================================

# NESTED DICTIONARY CYBER RANGE SIMULATION LAUNCHER (SYNTAX HARDENED)

# =======================================================================


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


# -----------------------------------------------------------------------

# STEP 1: DYNAMIC COUNTRY SELECTION VIA PYTHON

# -----------------------------------------------------------------------

echo "[*] Querying Threat Intelligence Regional Matrix..."


active_regions_str=$(python3 -c "

import yaml, sys

try:

    with open('$CATALOG', 'r') as f:

        data = yaml.load(f, Loader=yaml.SafeLoader)

    catalog_root = data.get('apt_catalog', {})

    countries = list(catalog_root.keys())

    print(','.join(countries))

except Exception:

    sys.exit(1)

")


IFS=',' read -r -a countries <<< "$active_regions_str"


if [ ${#countries[@]} -eq 0 ]; then

    countries=("China" "Russia" "Iran" "North Korea")

fi


echo "Select Target Threat Actor Country of Origin:"

echo "------------------------------------------------------------------------"

for i in "${!countries[@]}"; do

    echo "$((i+1)) ) ${countries[$i]}"

done

echo "------------------------------------------------------------------------"

read -p "Choose an origin region (1-${#countries[@]}): " country_choice


if ! [[ "$country_choice" =~ ^[0-9]+$ ]] || [ "$country_choice" -lt 1 ] || [ "$country_choice" -gt "${#countries[@]}" ]; then

    echo "[ERROR] Invalid selection fallback sequence initiated: China selected."

    selected_country="China"

else

    selected_country="${countries[$((country_choice-1))]}"

fi


# -----------------------------------------------------------------------

# STEP 2: DYNAMIC ADVANCED PERSISTENT THREAT (APT) SELECTION

# -----------------------------------------------------------------------

echo ""

echo "[*] Parsing available profiles associated with $selected_country..."


# Export selected country to environment to prevent python string breakout bugs

export SELECTED_COUNTRY="$selected_country"

export CATALOG_PATH="$CATALOG"


actors_json=$(python3 -c "

import yaml, json, sys, os

try:

    with open(os.environ['CATALOG_PATH'], 'r') as f:

        data = yaml.load(f, Loader=yaml.SafeLoader)

    actors = data.get('apt_catalog', {}).get(os.environ['SELECTED_COUNTRY'], [])

    print(json.dumps(actors))

except Exception:

    sys.exit(1)

")


if [ -z "$actors_json" ] || [ "$actors_json" == "[]" ]; then

    echo "[ERROR] No structural threat groups tracked for $selected_country."

    exit 1

fi


echo ""

echo "Select Target Threat Profile Engine:"

echo "------------------------------------------------------------------------"

# Export raw JSON data array directly to env context safely

export ACTORS_JSON_DATA="$actors_json"


python3 -c "

import json, os

actors = json.loads(os.environ['ACTORS_JSON_DATA'])

for idx, actor in enumerate(actors):

    print(f'{idx+1}) {actor[\"name\"]} ({actor[\"id\"]})')

"

echo "------------------------------------------------------------------------"

read -p "Select threat profile element: " actor_choice


total_actors=$(python3 -c "import json, os; print(len(json.loads(os.environ['ACTORS_JSON_DATA'])))")


if ! [[ "$actor_choice" =~ ^[0-9]+$ ]] || [ "$actor_choice" -lt 1 ] || [ "$actor_choice" -gt "$total_actors" ]; then

    echo "[ERROR] Out of bounds. Extracting default operational matrix placeholder..."

    actor_choice=1

fi


export ACTOR_CHOICE_INDEX="$actor_choice"


# RESOLVED: Pull attributes individually out of Python to eliminate IFS pipe splitting bugs

actor_name=$(python3 -c "import json, os;   actors = json.loads(os.environ['ACTORS_JSON_DATA']); choice = int(os.environ['ACTOR_CHOICE_INDEX']) - 1; print(actors[choice]['name'])")

actor_id=$(python3 -c "import json, os;     actors = json.loads(os.environ['ACTORS_JSON_DATA']); choice = int(os.environ['ACTOR_CHOICE_INDEX']) - 1; print(actors[choice]['id'])")


# -----------------------------------------------------------------------

# STEP 3: TIMING WINDOW MATRIX DEFINITION

# -----------------------------------------------------------------------

echo ""

echo "Select Campaign Timeline Profile Window:"

echo "------------------------------------------------------------------------"

echo "1) Test Mode (Instant execution verification - 5s Checkpoint)"

echo "2) 30 Minutes (Short compressed live evaluation run)"

echo "3) 24 Hours (Full day persistent training window)"

echo "4) 72 Hours (Advanced multi-day continuous hunt window)"

echo "------------------------------------------------------------------------"

read -p "Choose window speed (1-4): " time_choice


case $time_choice in

    1) sim_duration="test" ;;

    2) sim_duration="30m" ;;

    3) sim_duration="24h" ;;

    4) sim_duration="72h" ;;

    *) sim_duration="test" ;;

esac


# -----------------------------------------------------------------------

# STEP 4: OPERATIONAL WEIGHED NOISE BEHAVIOR SELECTION

# -----------------------------------------------------------------------

echo ""

echo "Select Campaign Opsec Profile Behavior:"

echo "------------------------------------------------------------------------"

echo "1) Mixed    (Unrestricted profiling behavior)"

echo "2) Noisy    (Prioritizes highly visible network/process actions)"

echo "3) Medium   (Prioritizes common operational footprints)"

echo "4) Stealthy (Prioritizes low-signature native execution)"

echo "------------------------------------------------------------------------"

read -p "Choose an option (1-4): " behavior_choice


case $behavior_choice in

    1) attack_behaviour="mixed" ;;

    2) attack_behaviour="noisy" ;;

    3) attack_behaviour="medium" ;;

    4) attack_behaviour="stealthy" ;;

    *) attack_behaviour="mixed" ;;

esac


# -----------------------------------------------------------------------

# STEP 5: CORE PLAYBOOK EXECUTION PIPELINE

# -----------------------------------------------------------------------

echo ""

echo "[+] Configuration Matrix Selected:"

echo "    - Origin Region       : $selected_country"

echo "    - Target Threat Actor : $actor_name ($actor_id)"

echo "    - Timing Window Mode  : $sim_duration"

echo "    - Weight Bias Element : $attack_behaviour"

echo "------------------------------------------------------------------------"

echo "[+] Wiping variable cache..."


rm -f runtime_vars.yml


echo "[*] Handing configuration targets off to Ansible Automation Engine..."

echo ""


# RESOLVED: Variables securely isolated within outer double quotes and inner single quotes

ansible-playbook -i inventory/hosts.ini site.yml -e "selected_actor_name='${actor_name}' selected_actor_id='${actor_id}' sim_duration='${sim_duration}' attack_behaviour='${attack_behaviour}'"
