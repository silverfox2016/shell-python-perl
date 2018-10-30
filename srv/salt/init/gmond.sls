gmond.conf:
  file.managed:
    - source: salt://init/files/gmond.conf
    - name: /usr/local/ganglia/etc/gmond.conf
    - user: root
    - group: root
    - mode: 644
