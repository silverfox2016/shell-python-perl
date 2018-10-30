/etc/rsyslog.conf:
  file.managed:
    - source: salt://files/sys/rsyslog.conf
    - user: root
    - group: root
    - mode: 644
  service:
    - name: rsyslog
    - running
    - restart: True
    - watch:
      - file: /etc/rsyslog.conf
/etc/rsyslog.d/userlog.conf:
  file.managed:
    - source: salt://files/sys/userlog.conf
    - user: root
    - group: root
    - mode: 644
  service:
    - name: rsyslog
    - running
    - restart: True
    - watch:
      - file: /etc/rsyslog.d/userlog.conf
