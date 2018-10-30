ipsetCreatEdit:
  file.managed:
    - source: salt://iptables/files/ipsetCreatEdit.sh
    - name: /opt/data/scripts/ipsetCreatEdit.sh
    - mode: 755
    - user: root
    - group: root

iptablesManager:
  file.managed:
    - source: salt://iptables/files/iptablesManager.sh
    - name: /opt/data/scripts/iptablesManager.sh
    - mode: 755
    - user: root
    - group: root

ipsetCreatEdit-run:
  cmd.run:
    - name: sh /opt/data/scripts/ipsetCreatEdit.sh
    - require:
      - file: /opt/data/scripts/ipsetCreatEdit.sh

iptablesManager-run:
  cmd.run:
    - name: sh /opt/data/scripts/iptablesManager.sh
    - require:
      - file: /opt/data/scripts/iptablesManager.sh

    
