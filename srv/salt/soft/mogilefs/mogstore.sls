mogilefs_store_conf:
  file.managed:
    - name: /etc/mogilefs/mogstored.conf
    - source: salt://soft/mogilefs/mogilefsd.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
mogile_storage_init:
  file.managed:
    - source: salt://soft/mogilefs/mogile_storage
    - name: /etc/init.d/mogile_storage
    - user: root
    - group: root
    - mode: 755