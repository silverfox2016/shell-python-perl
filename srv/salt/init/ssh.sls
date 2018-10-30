ssh:
  file.directory:
    - name: /lekan/src
    - mkdir: True
    - user: root
    - group: root

/lekan/src/openssh-6.8p1-1.x86_64.rpm:
  file.managed:
    - source: salt://files/ssh/openssh-6.8p1-1.x86_64.rpm
    - user: root
    - group: root

/lekan/src/openssl-1.0.1p-1.x86_64.rpm:
  file.managed:
    - source: salt://files/ssh/openssl-1.0.1p-1.x86_64.rpm
    - user: root
    - group: root

/lekan/src/libcrypto.so.1.0.0:
  file.managed:
    - source: salt://files/ssh/libcrypto.so.1.0.0
    - user: root
    - group: root

/lekan/src/ssh_install.sh:
  cmd.script:
    - source: salt://files/ssh/ssh_install.sh
    - shell: /bin/bash
    - require:
      - file: /lekan/src/openssh-6.8p1-1.x86_64.rpm
      - file: /lekan/src/openssl-1.0.1p-1.x86_64.rpm
      - file: /lekan/src/libcrypto.so.1.0.0


/etc/ssh/sshd_config:
  file.managed:
    - source: salt://files/ssh/sshd_config
    - user: root
    - group: root
    - mode: 644
  service:
    - name: sshd
    - running
    - reload: True
    - watch:
      - file: /etc/ssh/sshd_config
