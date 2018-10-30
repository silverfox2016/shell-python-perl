/usr/local/script:
  file.directory:
    - mkdir: True
    - user: root
    - group: root
/usr/local/script/tar_resin_log.sh:
  file.managed:
    - source: salt://xianglong.meng/tar_resin_log.sh
    - mode: 755
    - user: root
    - group: root
    - require:
      - file: /usr/local/script
/etc/cron.d/lekan-resinlog-gz:
  file.managed:
    - source: salt://xianglong.meng/lekan-resinlog-gz
    - mode: 644
    - user: root
    - group: root
  service.running:
    - name: crond
    - reload: True
    - require:
      - file: /usr/local/script/tar_resin_log.sh
      - file: /etc/cron.d/lekan-resinlog-gz
