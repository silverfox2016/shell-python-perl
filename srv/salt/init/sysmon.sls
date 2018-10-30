/usr/local/script:
  file.directory:
    - mkdir: True
    - user: root
    - group: root
/usr/local/script/sysmon.pl:
  file.managed:
    - source: salt://files/monitor/sysmon.pl
    - mode: 644
    - user: root
    - group: root
    - require:
      - file: /usr/local/script
/etc/cron.d/lekan-sysmon:
  file.managed:
    - source: salt://files/monitor/lekan-sysmon
    - mode: 644
    - user: root
    - group: root
  service.running:
    - name: crond
    - reload: True
    - require:
      - file: /usr/local/script/sysmon.pl
      - file: /etc/cron.d/lekan-sysmon
