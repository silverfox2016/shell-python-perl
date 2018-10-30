ulimit:
  watch:
    - file: /etc/security/limits.conf
/etc/security/limits.conf:
  file.managed:
    - source: salt://files/sys/limits.conf
    - user: root
    - group: root
    - mode: 644
  

