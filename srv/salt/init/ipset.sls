limits:
  file.managed:
    - source: salt://init/files/ipset
    - name: /etc/sysconfig/ipset
    - user: root
    - group: root
    - mode: 600
