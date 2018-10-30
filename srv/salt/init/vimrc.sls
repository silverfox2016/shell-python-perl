/etc/vimrc:
  file.managed:
    - source: salt://files/sys/vimrc
    - user: root
    - group: root
    - mode: 644
    
