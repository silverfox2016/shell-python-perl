salt-minion:
  pkg.installed:
{%- if grains['osfinger'] == 'CentOS-5' %}
    - version: 2016.11.3-2.el5 
{%- elif grains['osfinger'] == 'CentOS-6' %}
    - version: 2016.11.7-1.el6
    - allow_updates: True
{%- endif %}
