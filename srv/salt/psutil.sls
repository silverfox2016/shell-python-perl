python-psutil:
  pkg.installed:
{%- if grains['osfinger'] == 'CentOS-5' %}
    - name: python26-psutil
    - version: 0.6.1-2.el5
{%- elif grains['osfinger'] == 'CentOS-6' %}
    - name: python-psutil
    - version: 0.6.1-1.el6
{%- endif %}

