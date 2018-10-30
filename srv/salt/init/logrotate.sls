/etc/logrotate.conf:
  file.managed:
    - source: salt://files/sys/logrotate.conf
    - user: root
    - group: root
    - mode: 644
/etc/logrotate.d/syslog:
  file.managed:
    - source: salt://files/sys/syslog
    - user: root
    - group: root
    - mode: 644
