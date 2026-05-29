import pandas as pd

import yaml


# ----------------------------

# INPUT FILES

# ----------------------------


attr_file = "country attribution for YAML.csv"

noise_file = "noise model 2 with known users for YAML.csv"


# ----------------------------

# LOAD DATA

# ----------------------------


attr_df = pd.read_csv(attr_file, encoding="cp1252", low_memory=False)

noise_df = pd.read_csv(noise_file, encoding="cp1252", low_memory=False)


print(f"Loaded {len(attr_df)} actors")

print(f"Loaded {len(noise_df)} techniques")


# ----------------------------

# HUNTING QUERIES

# ----------------------------


HUNT_QUERIES = {

    "T1059.001": {

        "description": "Suspicious PowerShell execution",

        "kql": "process.name:powershell.exe AND process.command_line:(*-enc* OR *IEX*)"

    },

    "T1047": {

        "description": "WMIC execution",

        "kql": "process.name:wmic.exe"

    },

    "T1078": {

        "description": "Valid account anomalies",

        "kql": "event.category:authentication AND event.outcome:success"

    },

    "T1021.002": {

        "description": "SMB lateral movement",

        "kql": "network.protocol:smb AND destination.port:445"

    },

    "T1071.004": {

        "description": "DNS beaconing",

        "kql": "dns.question.name:* AND dns.question.length > 50"

    }

}


# ----------------------------

# BUILD APT CATALOG

# ----------------------------


apt_catalog = {}


for _, row in attr_df.iterrows():

    attr = str(row.get("Attribution", "Other")).strip()


    if attr not in apt_catalog:

        apt_catalog[attr] = []


    apt_catalog[attr].append({

        "name": str(row.get("Name", "")),

        "id": str(row.get("ID", "")),

        "groups": str(row.get("Associated Groups", "")),

        "description": str(row.get("Description", ""))

    })


apt_catalog["Random"] = []


# ----------------------------

# HELPERS

# ----------------------------


def normalize_phase(p):

    if pd.isna(p):

        return None


    mapping = {

        "execution": "execution",

        "persistence": "persistence",

        "privilege-escalation": "privilege_escalation",

        "discovery": "discovery",

        "lateral-movement": "lateral_movement",

        "command-and-control": "c2",

        "exfiltration": "exfiltration"

    }


    return mapping.get(str(p).lower(), None)



def classify(score):

    try:

        score = int(score)

    except:

        score = 5


    if score <= 3:

        return "noisy"

    elif score <= 7:

        return "medium"

    else:

        return "stealthy"


# ----------------------------

# BUILD MATRIX

# ----------------------------


group_cols = [c for c in noise_df.columns if c.startswith("groups")]


attack_matrix = {}


for _, row in noise_df.iterrows():


    technique = str(row.get("technique", "")).strip()

    name = str(row.get("Action", "")).strip()


    stealth_raw = row.get("Stealth", 5)

    noise_raw = row.get("Noise2", 5)


    stealth_class = classify(stealth_raw)


    # phases

    phases = []

    for col in ["Phase", "Phase2", "Phase3"]:

        p = normalize_phase(row.get(col))

        if p:

            phases.append(p)


    if not phases:

        continue


    # actors

    actors = []

    for g in group_cols:

        val = row.get(g)

        if pd.notna(val) and str(val).startswith("G"):

            actors.append(str(val))


    if not actors:

        continue


    # hunt logic

    hunt = HUNT_QUERIES.get(technique, {

        "description": "Generic suspicious behaviour",

        "kql": f"process.command_line:*{technique}*"

    })


    for actor in actors:


        if actor not in attack_matrix:

            attack_matrix[actor] = {}


        for phase in phases:


            if phase not in attack_matrix[actor]:

                attack_matrix[actor][phase] = []


            attack_matrix[actor][phase].append({

                "name": name,

                "technique": technique,

                "stealth": stealth_class,

                "score": {

                    "stealth": int(stealth_raw) if str(stealth_raw).isdigit() else 5,

                    "noise": int(noise_raw) if str(noise_raw).isdigit() else 5

                },

                "hunt": hunt

            })


# ----------------------------

# DEDUP

# ----------------------------


for actor in attack_matrix:

    for phase in attack_matrix[actor]:


        seen = set()

        clean = []


        for item in attack_matrix[actor][phase]:

            if item["technique"] not in seen:

                seen.add(item["technique"])

                clean.append(item)


        attack_matrix[actor][phase] = clean


# ----------------------------

# SAVE FILES

# ----------------------------


with open("vars/apt_catalog.yml", "w") as f:

    yaml.dump({"apt_catalog": apt_catalog}, f, sort_keys=False)


with open("vars/mitre_attack_matrix.yml", "w") as f:

    yaml.dump({"attack_matrix": attack_matrix}, f, sort_keys=False)


print("✅ Done")
