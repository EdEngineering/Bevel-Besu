apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: {{ name }}-{{ peer_name }}
  namespace: {{ peer_ns }}
  annotations:
    fluxcd.io/automated: "false"
spec:
  interval: 1m
  releaseName: {{ name }}-{{ peer_name }}
  chart:
    spec:
      interval: 1m
      sourceRef:
        kind: GitRepository
        name: flux-{{ network.env.type }}
        namespace: flux-{{ network.env.type }}
      chart: {{ charts_dir }}/peernode    
  values:
{% if network.upgrade is defined %}
    upgrade: {{ network.upgrade }}
{% endif %}
    metadata:
      namespace: {{ peer_ns }}
      images:
        couchdb: {{ couchdb_image }}
        peer: {{ peer_image }}
        alpineutils: {{ alpine_image }}
{% if network.env.annotations is defined %}
    annotations:  
      service:
{% for item in network.env.annotations.service %}
{% for key, value in item.items() %}
        - {{ key }}: {{ value | quote }}
{% endfor %}
{% endfor %}
      pvc:
{% for item in network.env.annotations.pvc %}
{% for key, value in item.items() %}
        - {{ key }}: {{ value | quote }}
{% endfor %}
{% endfor %}
      deployment:
{% for item in network.env.annotations.deployment %}
{% for key, value in item.items() %}
        - {{ key }}: {{ value | quote }}
{% endfor %}
{% endfor %}
{% endif %}        
    peer:
      name: {{ peer_name }}
      gossippeeraddress: {{ peer.gossippeeraddress }}
{% if provider == 'none' %}
      gossipexternalendpoint: {{ peer_name }}.{{ peer_ns }}:7051
{% else %}
      gossipexternalendpoint: {{ peer_name }}.{{ peer_ns }}.{{item.external_url_suffix}}:8443
{% endif %}
      localmspid: {{ name }}MSP
      loglevel: info
      tlsstatus: true
      builder: hyperledger/fabric-ccenv:{{ network.version }}
      couchdb:
        username: {{ name }}-user
{% if peer.configpath is defined %}
      configpath: conf/{{ peer_name }}_{{ name }}_core.yaml
      core: |-
{{ core_file | indent(width=8, first=True) }}
{% endif %}

    storage:
      peer:
        storageclassname: {{ name }}sc
        storagesize: 512Mi
      couchdb:
        storageclassname: {{ name }}sc
        storagesize: 1Gi

    vault:
      role: vault-role
      address: {{ vault.url }}
      authpath: {{ network.env.type }}{{ namespace }}-auth
      secretprefix: {{ vault.secret_path | default('secretsv2') }}/data/crypto/peerOrganizations/{{ namespace }}/peers/{{ peer_name }}.{{ namespace }}
      secretambassador: {{ vault.secret_path | default('secretsv2') }}/data/crypto/peerOrganizations/{{ namespace }}/ambassador
      serviceaccountname: vault-auth
      imagesecretname: regcred
      secretcouchdbpass: {{ vault.secret_path | default('secretsv2') }}/data/credentials/{{ namespace }}/couchdb/{{ name }}?user

    service:
      servicetype: ClusterIP
      ports:
        grpc:
          clusteripport: {{ peer.grpc.port }}
{% if peer.grpc.nodePort is defined %}
          nodeport: {{ peer.grpc.nodePort }}
{% endif %}
        events:
          clusteripport: {{ peer.events.port }}
{% if peer.events.nodePort is defined %}
          nodeport: {{ peer.events.nodePort }}
{% endif %}
        couchdb:
          clusteripport: {{ peer.couchdb.port }}
{% if peer.couchdb.nodePort is defined %}
          nodeport: {{ peer.couchdb.nodePort }}
{% endif %}
        metrics: 
          enabled: {{ peer.metrics.enabled | default(false) }}
          clusteripport: {{ peer.metrics.port | default(9443) }}     
    proxy:
      provider: "{{ network.env.proxy }}"
      external_url_suffix: {{ item.external_url_suffix }}

    config:
      pod:
        resources:
          limits:
            memory: 512M
            cpu: 1
          requests:
            memory: 512M
            cpu: 0.5
