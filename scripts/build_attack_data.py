import pandas as pd

import yaml

import random



print("Starting build process")



# ----------------------------

# LOAD CSV FILE_phase(row.get("Phase"))# LOAD CSV FILES

    p2 = normalize_phase(row.get("Phase2"))

    p3 = normalize_phase(row.get("Phase3"))



    if p1:

        phases.append(p1)

    if p2:

        phases.append(p2)

    if p3:

        phases.append(p3)



    # Default phase if none

    if len(phases) == 0:

        phases = ["execution"]



    # Collect actors

    actor_ids = []



    for col in group_columns:

        val = row.get(col)



        if pd.notna(val):

            actor_id = str(val).strip()



            if actor_id.startswith("G"):

                actor_ids.append(actor_id)



    # Assign actor if missing

    if len(actor_ids) == 0 and len(valid_actor_ids) > 0:

        actor_ids.append(random.choice(valid_actor_ids))



    if len(actor_ids) == 0:

        continue



    # Build action entry

    action_entry = {

        "name": str(action),

        "technique": str(technique),

        "stealth": "medium"

    }



    for actor_id in actor_ids:



        if actor_id not in attack_matrix:

            attack_matrix[actor_id] = {}



        for phase in phases:



            if phase not in attack_matrix[actor_id]:

                attack_matrix[actor_id][phase] = []



            attack_matrix[actor_id][phase].append(action_entry)



print("attack_matrix size:", len(attack_matrix))



# ----------------------------

# BUILD APT CATALOG (FIXED COUNTRY)

# ----------------------------



apt_catalog = {}



for _, row in apt_df.iterrows():



    name = row.get("Name")

    actor_id = row.get("ID")

    country_value = row.get("Attribution")



    if pd.isna(name):

        continue



    actor_name = str(name).strip()



    # ✅ FIX: no empty countries

    if pd.isna(country_value) or str(country_value).strip() == "":

        clean_country = "Unknown"

    else:

        clean_country = str(country_value).strip()



    apt_catalog[actor_name] = {

        "id": str(actor_id).strip() if pd.notna(actor_id) else "",

        "name": actor_name,

        "country": clean_country

    }



print("apt_catalog size:", len(apt_catalog))



# ----------------------------

# WRITE YAML FILES

# ----------------------------



with open("vars/mitre_attack_matrix.yml", "w") as f:

    yaml.safe_dump({"attack_matrix": attack_matrix}, f, sort_keys=False)



with open("vars/apt_catalog.yml", "w") as f:

    yaml.safe_dump({"apt_catalog": apt_catalog}, f, sort_keys=False)



print("Build complete")

# ----------------------------



tech_df = pd.read_csv(

    "noise model 2 with known users for YAML.csv",

    encoding="latin1"

)



apt_df = pd.read_csv(

    "country attribution for YAML.csv",

    encoding="latin1"

)



print("CSV files loaded")



# ----------------------------

# NORMALIZE PHASE

# ----------------------------



def normalize_phase(value):

    if pd.isna(value):

        return None



    text = str(value).lower()



    if "initial" in text:

        return "initial_access"

    elif "execution" in text:

        return "execution"

    elif "persistence" in text:

        return "persistence"

    elif "lateral" in text:

        return "lateral_movement"

    elif "collection" in text:

        return "collection"

    elif "command" in text or "control" in text:

        return "c2"

    elif "exfil" in text:

        return "exfiltration"



    return None



# ----------------------------

# FIND GROUP COLUMNS

# ----------------------------



group_columns = []



for col in tech_df.columns:

    if col.startswith("groups."):

        group_columns.append(col)



# ----------------------------

# COLLECT VALID ACTOR IDS

# ----------------------------



valid_actor_ids = []



for col in group_columns:

    for val in tech_df[col].dropna():

        actor_id = str(val).strip()



        if actor_id.startswith("G") and actor_id not in valid_actor_ids:

            valid_actor_ids.append(actor_id)



print("Valid actor IDs found:", len(valid_actor_ids))



# ----------------------------

# BUILD ATTACK MATRIX

# ----------------------------



attack_matrix = {}



for _, row in tech_df.iterrows():



    technique = row.get("technique")

    action = row.get("Action")



    if pd.isna(technique) or pd.isna(action):

        continue



    # Collect phases

    phases = []



