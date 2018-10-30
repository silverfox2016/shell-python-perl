/usr/local/zabbix/etc/zabbix_agentd.conf.d/userparameter_networkspeed.conf:
  file.managed:
    - source: salt://init/files/userparameter_networkspeed.conf
    - user: root
    - group: root
    - mode: 755


/usr/local/zabbix/bin/network_tocal.sh:
  file.managed:
    - source: salt://init/files/network_tocal.sh
    - user: root
    - group: root
    - mode: 755
