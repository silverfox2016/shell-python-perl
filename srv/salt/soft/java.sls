java_install:
  file.managed:
    - source: salt://files/soft/java/java-1.8.0_05_240.34_2015-01-06.tar.bz2
    - name: /lekan/java-1.8.0_05_240.34_2015-01-06.tar.bz2 
  cmd.script:
    - source: salt://files/soft/java/java.sh
    - shell: /bin/bash
    - require:
      - file: /lekan/java-1.8.0_05_240.34_2015-01-06.tar.bz2
