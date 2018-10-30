fqdn_conf:  
  file.managed:  
    - name: /etc/hostname
    - source: salt://files/hostname
    - user: root  
    - group: root  
    - mode: 640  
    - template: jinja  
    - defaults:  
      fqdn_id: {{ grains['id'] }}  
minion_service:  
  service.running:  
    - name: salt-minion  
    - enable: True  
    - require:  
      - file: fqdn_conf
