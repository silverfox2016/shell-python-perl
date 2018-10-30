/usr/local/script:
  file.directory:
    - mkdir: True
    - user: root
    - group: root
/usr/local/script/tar_tomcat_log.sh:
  file.managed:
    - source: salt://xianglong.meng/tar_tomcat_log.sh
    - mode: 755
    - user: root
    - group: root
    - require:
      - file: /usr/local/script
/etc/cron.d/lekan-tomcat-log-gz:
  file.managed:
    - source: salt://xianglong.meng/lekan-tomcat-log-gz
    - mode: 644
    - user: root
    - group: root
  service.running:
    - name: crond
    - reload: True
    - require:
      - file: /usr/local/script/tar_tomcat_log.sh
      - file: /etc/cron.d/lekan-tomcat-log-gz
