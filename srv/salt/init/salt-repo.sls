pkgs:
  {% if grains['os_family'] == '5.5' %}
     - name: rpm -ivh https://repo.saltstack.com/yum/redhat/salt-repo-latest-1.el5.noarch.rpm --nodeps
  {% elif grains['os_family'] == '6' %}
     - name: rpm -ivh  https://repo.saltstack.com/yum/redhat/salt-repo-latest-1.el6.noarch.rpm --nodeps
  {% endif %}
