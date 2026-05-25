#!/bin/bash


clear


echo "======================================"

echo "   APT SIMULATION CONTROL PANEL V3"

echo "======================================"

echo ""


# ------------ ACTOR SELECTION ------------


echo "Select Actor:"

echo "1 - APT34"

read ACTOR


case $ACTOR in

1) actor="vars/actors/apt34.yml" ;;

*) echo "Invalid selection"; exit 1 ;;

esac


# ------------ MODE SELECTION ------------


echo ""

echo "Select Execution Mode:"

echo "1 - Full Campaign (Complete MITRE chain per run)"

echo "2 - Stateful Attack (One phase per run)"

read MODE_SELECT


if [ "$MODE_SELECT" == "1" ]; then

  mode="full"

elif [ "$MODE_SELECT" == "2" ]; then

  mode="stateful"

else

  echo "Invalid selection"

  exit 1

fi


# ------------ DURATION SELECTION ------------


echo ""

echo "Select Duration:"

echo "1 - Short (30–60 minutes)"

echo "2 - Medium (12–24 hours)"

echo "3 - Long (24–72 hours)"

echo "4 - Continuous"

read DURATION


case $DURATION in

1)

  total_runtime=3600

  sleep_min=180

  sleep_max=420

  ;;

2)

  total_runtime=86400

  sleep_min=600

  sleep_max=1800

  ;;

3)

  total_runtime=259200

  sleep_min=900

  sleep_max=3600

  ;;

4)

  total_runtime=999999999

  sleep_min=600

  sleep_max=1800

  ;;

*)

  echo "Invalid selection"; exit 1 ;;

esac


echo ""

echo "[+] Actor: $actor"

echo "[+] Mode: $mode"

echo "[+] Simulation starting..."

echo ""


start_time=$(date +%s)

run=1

phase_index=0


phases=("execution" "persistence" "identity" "lateral" "c2" "exfil")


# ------------ MAIN LOOP ------------


while true

do

  current_time=$(date +%s)

  elapsed=$((current_time - start_time))


  if [ $elapsed -ge $total_runtime ]; then

    break

  fi


  echo ""

  echo "--------------------------------------"

  echo "[+] Run $run"

  echo "--------------------------------------"


  if [ "$mode" == "full" ]; then


    ansible-playbook -i inventory/hosts.ini playbooks/campaign.yml -e "actor_file=$actor"


  else

    current_phase=${phases[$phase_index]}


    echo "[+] Stateful phase: $current_phase"


    ansible-playbook -i inventory/hosts.ini playbooks/campaign.yml \

    -e "actor_file=$actor single_phase=$current_phase"


    phase_index=$(( (phase_index + 1) % ${#phases[@]} ))

  fi


  sleep_time=$((sleep_min + RANDOM % (sleep_max - sleep_min + 1)))


  echo "[+] Sleeping for $sleep_time seconds..."

  sleep $sleep_time


  run=$((run + 1))

done


echo ""

echo "[✓] Simulation complete"
