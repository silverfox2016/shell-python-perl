Mogilefs_install:
  file.managed:
    - source: salt://files/MogileFS-Server-2.59.tar.gz
    - name: /root/MogileFS-Server-2.59.tar.gz
  cmd.script:
    - source: salt://files/mogilefs-server.sh
    - shell: /bin/bash
    - unless: test -d /etc/mogilefs/
    - require:
      - file: /root/MogileFS-Server-2.59.tar.gz

  
