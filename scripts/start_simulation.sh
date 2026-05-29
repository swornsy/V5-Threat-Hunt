#!/bin/bash


echo "=============================="

echo " Threat Simulation Framework"

echo "=============================="


# ----------------------------

# GET ATTRIBUTIONS

# ----------------------------


ATTR_LIST=$(python3 -c "import yaml; d=yaml.safe_load(open('vars/apt_catalog.yml')); print('|'.join(d['apt_catalog'].keys()))")


IFS='|' read -ra ATTR_ARRAY <<< "$ATTR_LIST"


echo ""

echo "Select Attribution:"


select attribution in "${ATTR_ARRAY[@]}"; do

  [[ -n "$attribution" ]] && break

done


echo "DEBUG: attribution=$attribution"


# ----------------------------

# GET ACTORS

# ----------------------------


ACTOR_LINES=$(python3 -c "

import yaml

d=yaml.safe_load(open('vars/apt_catalog.yml'))

actors=d['apt_catalog'].get(\"$attribution\", [])

out=[]

for i,a in enumerate(actors):

    name=str(a.get('name','')).replace('|',' ')

    aid=str(a.get('id',''))

    grp=str(a.get('groups','')).replace('|',' ')

    desc=str(a.get('description','')).replace('\\n',' ').replace('|',' ')

    out.append(f'{i+1}|{name}|{aid}|{grp}|{desc}')

print('|||'.join(out))

")


IFS='|||' read -ra ACTOR_ARRAY <<< "$ACTOR_LINES"


echo ""

echo "Available Actors:"


for line in "${ACTOR_ARRAY[@]}"; do

  echo "$line" | awk -F'|' '{print $1") "$2}'

done


echo ""

read -p "Select actor number: " choice


SELECTED="${ACTOR_ARRAY[$((choice-1))]}"


echo "DEBUG: raw selection=$SELECTED"


actor_name=$(echo "$SELECTED" | cut -d'|' -f2)

actor_id=$(echo "$SELECTED" | cut -d'|' -f3)

actor_groups=$(echo "$SELECTED" | cut -d'|' -f4)

actor_desc=$(echo "$SELECTED" | cut -d'|' -f5-)


echo "DEBUG: actor_name=$actor_name"

echo "DEBUG: actor_id=$actor_id"


# ----------------------------

# VALIDATION

# ----------------------------


if [[ -z "$actor_id" ]]; then

  echo "❌ ERROR: Actor ID is empty"

  exit 1

fi


# ----------------------------

# CONFIRM

# ----------------------------


echo ""

echo "=== Actor Selected ==="

echo "Name: $actor_name"

echo ""

echo "Groups: $actor_groups"

echo ""

echo "Description:"

echo "$actor_desc"

echo ""


read -p "Proceed? (yes/no): " confirm

[[ "$confirm" != "yes" ]] && exit 1


# ----------------------------

# MODE

# ----------------------------


echo ""

echo "Select Mode:"

echo "1) Single"

echo "2) Full"

echo "3) Temporal"


read -p "Choice: " m


case $m in

  1) attack_mode="single" ;;

  2) attack_mode="full" ;;

  3) attack_mode="temporal" ;;

  *) echo "Invalid mode"; exit 1 ;;

esac


echo "DEBUG: mode=$attack_mode"


# ----------------------------

# BEHAVIOUR

# ----------------------------


echo ""

echo "Select Behaviour:"

echo "1) Noisy"

echo "2) Medium"

echo "3) Stealthy"

echo "4) Mixed"


read -p "Choice: " b


case $b in

  1) attack_behaviour="noisy" ;;

  2) attack_behaviour="medium" ;;

  3) attack_behaviour="stealthy" ;;

  4) attack_behaviour="mixed" ;;

  *) attack_behaviour="mixed" ;;

esac


echo "DEBUG: behaviour=$attack_behaviour"


# ----------------------------

# DURATION (YOUR MODEL ✅)

# ----------------------------


echo ""

echo "Select exercise duration:"

echo "1) 30-60 minutes"

echo "2) 12-24 hours"

echo "3) 24-72 hours"

echo "4) Continuous"


read -p "Choice: " d


case $d in

  1) duration=60 ;;

  2) duration=1440 ;;

  3) duration=4320 ;;

  4) duration=999999 ;;

  *) duration=60 ;;

esac


echo "DEBUG: duration=$duration"


# ----------------------------

# FINAL DEBUG

# ----------------------------


echo ""

echo "=============================="

echo " FINAL DEBUG"

echo "=============================="

echo "selected_actor_name=$actor_name"

echo "selected_actor_id=$actor_id"

echo "attack_mode=$attack_mode"

echo "attack_behaviour=$attack_behaviour"

echo "attack_duration=$duration"

echo "=============================="


# ----------------------------

# ✅ WRITE RUNTIME VARS FILE (FIXES YOUR ERROR)

# ----------------------------


cat > runtime_vars.yml <<EOF

selected_actor_name: "$actor_name"

selected_actor_id: "$actor_id"

attack_mode: "$attack_mode"

attack_behaviour: "$attack_behaviour"

attack_duration: "$duration"

EOF


echo ""

echo "DEBUG: runtime_vars.yml created:"

cat runtime_vars.yml


# ----------------------------

# RUN ANSIBLE ✅

# ----------------------------


ansible-playbook site.yml -vv -e "@runtime_vars.yml"


echo ""

echo "✅ Simulation complete"
