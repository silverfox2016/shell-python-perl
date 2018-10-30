ntpd:
  pkg:
    - name: ntp
    - installed
  file.managed:
    - source: salt://files/ntp.conf
    - name: /etc/ntp.conf
    - user: root
    - group: root
    - mode: 644
  service:
    - running
    - name: ntpd
    - enable: True
    - restart: True
    - watch:
      - file: /etc/ntp.conf

  
