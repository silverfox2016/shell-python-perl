selinux:
  watch:
    - file: /etc/selinux/config
/etc/selinux/config:
  file.managed:
    - source: salt://files/sys/selinux/config
    - user: root
    - group: root
    - mode: 644

