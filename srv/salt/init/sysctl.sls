/etc/sysctl.conf:
  file.managed:
    - source: salt://files/sys/sysctl.conf
    - user: root
    - group: root
sysctl -p:
  cmd.run:
    - name: sysctl -p
    - requier:
      - file: /etc/sysctl.conf

