apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: {{ component_name }}
  namespace: {{ name | lower | e }}-net
  annotations:
    fluxcd.io/automated: "false"
spec:
  interval: 1m
  releaseName: {{ component_name }}
  chart:
    spec:
      interval: 1m
      sourceRef:
        kind: GitRepository
        name: flux-{{ network.env.type }}
        namespace: flux-{{ network.env.type }}
      chart: {{ charts_dir }}/install_chaincode
  values:
    metadata:
      namespace: {{ namespace }}
      network:
        version: {{ network.version }}
      images:
        fabrictools: {{ fabrictools_image }}
        alpineutils: {{ alpine_image }}
    peer:
      name: {{ peer_name }}
      address: {{ peer_address }}
      localmspid: {{ name }}MSP
      loglevel: debug
      tlsstatus: true
    vault:
      role: vault-role
      address: {{ vault.url }}
      authpath: {{ network.env.type }}{{ namespace | e }}-auth
      adminsecretprefix: {{ vault.secret_path | default('secretsv2') }}/data/crypto/peerOrganizations/{{ namespace }}/users/admin 
      orderersecretprefix: {{ vault.secret_path | default('secretsv2') }}/data/crypto/peerOrganizations/{{ namespace }}/orderer
      secretgitprivatekey: {{ vault.secret_path | default('secretsv2') }}/data/credentials/{{ namespace }}/git
      serviceaccountname: vault-auth
      imagesecretname: regcred
      tls: false
    orderer:
      address: {{ orderer_address }}
    chaincode:
      builder: hyperledger/fabric-ccenv:{{ network.version }}
      name: {{ component_chaincode.name | lower | e }}
      version: {{ component_chaincode.version }}
      lang: {{ component_chaincode.lang | default('golang') }}
      maindirectory: {{ component_chaincode.maindirectory }}
      repository:
        hostname: "{{ component_chaincode.repository.url.split('/')[0] | lower }}"
        git_username: "{{ component_chaincode.repository.username}}"
        url: {{ component_chaincode.repository.url }}
        branch: {{ component_chaincode.repository.branch }}
        path: {{ component_chaincode.repository.path }}
      endorsementpolicies:  {{ component_chaincode.endorsements | quote}}
