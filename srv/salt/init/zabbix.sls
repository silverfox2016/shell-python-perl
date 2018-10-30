zabbix_agentd:
  file.managed:
    - source: salt://files/monitor/zabbix_agentd.tar.gz
    - name: /lekan/zabbix_agentd.tar.gz
 
  cmd.script:
    - source: salt://files/monitor/zabbix_agentd_install.sh
    - shell: /bin/bash
    - require:
      - file: zabbix_agentd
