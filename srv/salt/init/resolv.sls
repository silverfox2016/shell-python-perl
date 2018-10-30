resolv:
  file.managed:
    - source: salt://init/files/resolv.conf
    - name: /etc/resolv.conf
    - user: root
    - group: root
    - mode: 640
