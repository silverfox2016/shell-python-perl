{% if grains['osmajorrelease'][0] == '5' %}
CentOS-Base:
  file.managed:
    - source: salt://files/repo/{{grains.osmajorrelease}}/CentOS-Base.repo
    - name: /etc/yum.repos.d/CentOS-Base.repo
CentOS-Debuginfo:
  file.managed:
    - source: salt://files/repo/{{grains.osmajorrelease}}/CentOS-Debuginfo.repo
    - name: /etc/yum.repos.d/CentOS-Debuginfo.repo
CentOS-fasttrack:
  file.managed:
    - source: salt://files/repo/{{grains.osmajorrelease}}/CentOS-fasttrack.repo
    - name: /etc/yum.repos.d/CentOS-fasttrack.repo
CentOS-Media:
  file.managed:
    - source: salt://files/repo/{{grains.osmajorrelease}}/CentOS-Media.repo
    - name: /etc/yum.repos.d/CentOS-Media.repo
CentOS-Sources.repo:
  file.managed:
    - source: salt://files/repo/{{grains.osmajorrelease}}/CentOS-Sources.repo
    - name: /etc/yum.repos.d/CentOS-Sources.repo
CentOS-Vault:
  file.managed:
    - source: salt://files/repo/{{grains.osmajorrelease}}/CentOS-Vault.repo
    - name: /etc/yum.repos.d/CentOS-Vault.repo
epel:
  file.managed:
    - source: salt://files/repo/{{grains.osmajorrelease}}/epel.repo
    - name: /etc/yum.repos.d/epel.repo
epel-testing:
  file.managed:
    - source: salt://files/repo/{{grains.osmajorrelease}}/epel-testing.repo
    - name: /etc/yum.repos.d/epel-testing.repo
salt-2016.11:
  file.managed:
    - source: salt://files/repo/{{grains.osmajorrelease}}/salt-2016.11.repo
    - name: /etc/yum.repos.d/salt-2016.11.repo
{% elif grains['osmajorrelease'][0] == '6' %}
CentOS-Base:
  file.managed:
    - source: salt://files/repo/{{grains.osmajorrelease}}/CentOS-Base.repo
    - name: /etc/yum.repos.d/CentOS-Base.repo
CentOS-Debuginfo:
  file.managed:
    - source: salt://files/repo/{{grains.osmajorrelease}}/CentOS-Debuginfo.repo
    - name: /etc/yum.repos.d/CentOS-Debuginfo.repo
CentOS-Media:
  file.managed:
    - source: salt://files/repo/{{grains.osmajorrelease}}/CentOS-Media.repo
    - name: /etc/yum.repos.d/CentOS-Media.repo
CentOS-Vault:
  file.managed:
    - source: salt://files/repo/{{grains.osmajorrelease}}/CentOS-Vault.repo
    - name: /etc/yum.repos.d/CentOS-Vault.repo
epel:
  file.managed:
    - source: salt://files/repo/{{grains.osmajorrelease}}/epel.repo
    - name: /etc/yum.repos.d/epel.repo
epel-testing:
  file.managed:
    - source: salt://files/repo/{{grains.osmajorrelease}}/epel-testing.repo
    - name: /etc/yum.repos.d/epel-testing.repo
CentOS-SCLo-scl:
  file.managed:
    - source: salt://files/repo/{{grains.osmajorrelease}}/CentOS-SCLo-scl.repo
    - name: /etc/yum.repos.d/CentOS-SCLo-scl.repo
CentOS-SCLo-scl-rh:
  file.managed:
    - source: salt://files/repo/{{grains.osmajorrelease}}/CentOS-SCLo-scl-rh.repo
    - name: /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo
salt-latest:
  file.managed:
    - source: salt://files/repo/{{grains.osmajorrelease}}/salt-latest.repo
    - name: /etc/yum.repos.d/salt-latest.repo
zabbix:
  file.managed:
    - source: salt://files/repo/{{grains.osmajorrelease}}/zabbix.repo
    - name: /etc/yum.repos.d/zabbix.repo
{%- endif %}
