{% set host = grains['ipv4'][0] %}
append-file:
  file.append:
    - name: /etc/filebeat/filebeat.yml
    - text: "beat.hostname: {{ host }}"
