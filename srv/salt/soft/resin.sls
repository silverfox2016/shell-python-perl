resin_install:
  file.managed:
    - source: salt://files/soft/resin/resin-3.1.11.tar.gz
    - name: /lekan/resin-3.1.11.tar.gz
  cmd.script:
    - source: salt://files/soft/resin/resin.sh
    - shell: /bin/bash
    - unless: test -d /usr/local/resin
    - require:
      - file: /lekan/resin-3.1.11.tar.gz
/usr/local/resin/conf:
  file.directory:
    - source: salt://files/soft/resin/conf
    - mkdir: True
    - user: root
    - group: root
