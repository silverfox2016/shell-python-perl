/etc/sudoers.d/dale:
  file.managed:
    - source: salt://files/user/dale
    - user: root
    - group: root
    - mode: 440

/etc/sudoers.d/qijun:
  file.managed:
    - source: salt://files/user/qijun
    - user: root
    - group: root
    - mode: 440

/etc/sudoers.d/yunsong:
  file.managed:
    - source: salt://files/user/yunsong
    - user: root
    - group: root
    - mode: 440

/etc/sudoers.d/xianglong:
  file.managed:
    - source: salt://files/user/xianglong
    - user: root
    - group: root
    - mode: 440

/etc/sudoers.d/yangshuo:
  file.managed:
    - source: salt://files/user/yangshuo
    - user: root
    - group: root
    - mode: 440
