include:
  - init.useradd
/etc/rsyslog.conf:
  file.managed:
    {% if grains['id'] == 'aws-monitor-210.142' %}
    - source: salt://files/rsyslog/rsyslog_master.conf
    {% else %}
    - source: salt://files/rsyslog/rsyslog.conf
    {% endif %} 
    - user: root
    - group: root
    - mode: 644
/etc/pki/rsyslog/ca.pem:
  file.managed:
    - source: salt://files/rsyslog/pki/ca.pem
    - user: root
    - group: root
    - mode: 600
/etc/rsyslog.d/userlog.conf:
  file.managed:
    - source: salt://files/rsyslog/userlog.conf
    - user: root
    - group: root
rsyslog-gnutls:
  pkg:
    - name: rsyslog-gnutls
    - installed
  service:
    - name: rsyslog
    - running
    - restart: Ture
    - require:
      - pkg: rsyslog-gnutls
    - watch:
      - file: /etc/rsyslog.conf
      - file: /etc/pki/rsyslog/ca.pem
      - file: /etc/rsyslog.d/userlog.conf

    
