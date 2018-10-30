history:
  watch:
    - file: /etc/profile.d/history.sh
/etc/profile.d/history.sh:
  file.managed:
    - source: salt://files/sys/history.sh
    - user: root
    - group: root
    - mode: 644 

. /etc/profile.d/history.sh:
  cmd.run:
    - onlyif: test -f /etc/profile.d/history.sh
