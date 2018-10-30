salt_install:
  pkg.installed:
    - name: salt-minion
  file.managed:
    - name: /etc/salt/minion
    - source: salt://minions/minion04
    - require:
      - pkg: salt-minion
