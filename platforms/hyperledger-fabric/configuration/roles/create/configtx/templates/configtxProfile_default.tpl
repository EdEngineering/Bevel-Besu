Profiles:
{% for channel in network.channels %}
  {{channel.genesis.name}}:
    <<: *ChannelDefaults
    Orderer:
      <<: *OrdererDefaults
{% if consensus.name == 'raft' %}
      OrdererType: etcdraft
      EtcdRaft:
        Consenters:
{% for orderer in orderers %}
{% set component_ns = orderer.org_name.lower() + '-net' %}
{% if provider == 'none' %}
        - Host: {{orderer.name}}.{{ component_ns }}
          Port: 7050
{% else %}
{% set path = orderer.uri.split(':') %}
        - Host: {{ path[0] }}
          Port: 8443
{% endif %}
          ClientTLSCert: ./crypto-config/ordererOrganizations/{{ component_ns }}/orderers/{{ orderer.name }}.{{ component_ns }}/tls/server.crt
          ServerTLSCert: ./crypto-config/ordererOrganizations/{{ component_ns }}/orderers/{{ orderer.name }}.{{ component_ns }}/tls/server.crt
{% endfor %}
{% endif %}
      Organizations:
{% for orderer in channel.orderers %}
        - *{{ orderer }}Org
{% endfor %}
    Consortiums:
      {{channel.consortium}}:
        Organizations:
{% for org in network.organizations %}
{% if org.type != 'orderer' %}
          - *{{org.name}}Org
{% endif %}          
{% endfor %}
  {{channel.channel_name}}:
    <<: *ChannelDefaults
    Consortium: {{channel.consortium}}
    Application:
      <<: *ApplicationDefaults
      Organizations:
{% for org in channel.participants %}
        - *{{org.name}}Org
{% endfor %}
{% endfor %}
