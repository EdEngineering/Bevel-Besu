metadata:
  namespace: {{ component_ns }}
  images:
    fabrictools: {{ fabrictools_image }}
    alpineutils: {{ alpine_image }}
storage:
  class: {{ storage_class }}
  size: 256Mi
vault:
  role: vault-role
  address: {{ vault.url }}
  authpath: {{ network.env.type }}{{ component_ns }}-auth
  adminsecretprefix: {{ vault.secret_path | default('secretsv2') }}/data/crypto/ordererOrganizations/{{ component_ns }}/users/admin
  orderersecretprefix: {{ vault.secret_path | default('secretsv2') }}/data/crypto/ordererOrganizations/{{ component_ns }}/orderers/{{ orderer_component }}
  serviceaccountname: vault-auth
  imagesecretname: regcred
  tls: false
peer:
  name: {{ orderer_name }}
  localmspid: {{ org.name | lower}}MSP
  tlsstatus: true
{% if network.env.proxy == 'none' %}
  address: {{ orderer_name }}.{{ component_ns }}:7051
orderer:
  address: {{ orderer_name }}.{{ component_ns }}:7051
{% else %}
  address: {{ orderer_address }}
orderer:
  address: {{ orderer_address }}
{% endif %}
