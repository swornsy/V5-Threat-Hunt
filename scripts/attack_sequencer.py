---
- name: V5 Threat Hunt Adversary Emulation Sequencer
  hosts: localhost
  gather_facts: no
  vars:
    # The simulation array mapping out our attack timeline
    threat_matrix:
      - { stage: "Discovery", mitre: "T1082", desc: "System Info Discovery", target: "off-wks01" }
      - { stage: "Discovery", mitre: "T1049", desc: "Network Connections Discovery", target: "off-wks01" }
      - { stage: "Credential Access", mitre: "T1003.001", desc: "LSASS Process Dump via Comsvcs", target: "off-wks01" }
      - { stage: "Lateral Movement", mitre: "T1021.002", desc: "SMB Session Creation to File Server", target: "fs01" }
      - { stage: "Collection", mitre: "T1114", desc: "Data Staging for Exfiltration", target: "fs01" }

  tasks:
    - name: Process Simulation Chain
      include_tasks: run_atomic_step.yml
      loop: "{{ threat_matrix }}"
      loop_control:
        loop_var: attack_step
