import os, json, random


actor_data = json.loads(os.environ["ACTOR_DATA"])

mode = os.environ.get("MODE", "mixed")


DWELL = {

    "noisy": (5, 30),

    "medium": (30, 300),

    "stealthy": (300, 1800),

    "mixed": (20, 600)

}


PHASE_FLOW = {

    "initial_access": ["execution"],

    "execution": ["persistence","discovery"],

    "persistence": ["lateral_movement"],

    "lateral_movement": ["collection"],

    "collection": ["c2"],

    "c2": ["exfiltration"],

    "exfiltration": []

}


def build():

    seq=[]

    phase="initial_access"

    burst=False

    burst_left=0


    for _ in range(50):

        if phase not in actor_data:

            break


        actions=actor_data[phase]

        action=random.choice(actions)


        if burst:

            delay=random.randint(1,10)

            burst_left-=1

            if burst_left<=0:

                burst=False

        else:

            base=random.randint(*DWELL.get(mode,DWELL["mixed"]))

            jitter=int(base*random.uniform(-0.3,0.3))

            delay=max(1,base+jitter)

            if random.random()<0.2:

                burst=True

                burst_left=random.randint(2,5)


        seq.append({

            "phase": phase,

            "name": action["name"],

            "technique": action["technique"],

            "stealth": action["stealth"],

            "delay": delay,

            "hunt": action.get("hunt", {}),

            "score": action.get("score", {"stealth":5,"noise":5})

        })


        next_p=PHASE_FLOW.get(phase,[])

        if not next_p:

            break

        phase=random.choice(next_p)


    return seq


print(json.dumps(build()))
