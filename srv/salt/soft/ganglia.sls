ganglia_install:
  file.managed:
    - source: salt://files/soft/ganglia/ganglia-3.6.1.tar.gz
    - name: /lekan/ganglia-3.6.1.tar.gz
  cmd.script:
    - source: salt://files/soft/ganglia/ganglia.sh
    - shell: /bin/bash
    - unless: test -d /usr/local/ganglia
    - require:
      - file: /lekan/ganglia-3.6.1.tar.gz
