lekanops:
  group.present:
    - gid: 600
{% for user in pillar['users'] %}
{{ user.name }}:
  group:
    - present
  user:
    - present
    - home: /home/{{ user.name }}
    - gid_from_name: True
    - shell: /bin/bash
    - password: {{ user.password }}
    - groups:
      - {{ user.name }}
      - lekanops
/home/{{ user.name }}/.bash_profile:
  file.managed:
    - source: salt://files/user/bash_profile
/home/{{ user.name }}/.ssh/authorized_keys:
  file.managed:
    - contents: {{ user.authorized_keys }}
    - makedirs: True
/etc/sudoers.d/{{ user.alias }}:
  file.managed:
    - source: salt://files/user/{{ user.alias }}
    - user: root
    - group: root
    - mode: 440
{% endfor %}

/root/.bash_profile:
  file.managed:
    - source: salt://files/user/bash_profile
