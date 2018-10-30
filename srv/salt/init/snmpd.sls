sudo-ldap:
  file.managed:
    - source: salt://init/files/sudo-ldap.conf
    - name: /etc/sudo-ldap.conf
    - user: root
    - group: root
    - mode: 640
