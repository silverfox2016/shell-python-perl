iptables_save:
  cmd.run:
    - name: iptables-save > /etc/sysconfig/iptables.old

iptables_file:
  file.managed:
    - source: salt://files/sys/iptables
    - name: /etc/sysconfig/iptables
    - user: root
    - group: root
    - mode: 600

iptables:
  service:
    - name: iptables
    - running
    - reload: True
    - watch:
      - file: /etc/sysconfig/iptables 
