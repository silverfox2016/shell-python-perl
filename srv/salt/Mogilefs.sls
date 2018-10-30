Mogilefs_install:
  file.managed:
    - source: salt://files/MogileFS-Server-2.59.tar.gz
    - name: /root/MogileFS-Server-2.59.tar.gz
  cmd.script:
    - source: salt://files/mogilefs-server.sh
    - shell: /bin/shell
    - unless: test -d /etc/mogilefs/
    - require:
      - file: /root/MogileFS-Server-2.59.tar.gz
mogile_trucker:
  - source: salt://files/mogile_trucker
  - name: /etc/init.d/mogile_trucker
  - require:
    - Mogilefs_install
mogile_storage:
  - source: salt://files/mogile_storage
  - name: /etc/init.d/mogile_storage
  - require:
    - Mogilefs_install
perl-CPAN:
  pkg.installed:
    - version: 1.9402-144.el6 
config:
  file.managed:
   - name: /usr/share/perl5/CPAN/Config.pm
   - source: salt://files/Config.pm

  
