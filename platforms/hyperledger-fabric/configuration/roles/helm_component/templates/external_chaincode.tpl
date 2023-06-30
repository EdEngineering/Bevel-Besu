apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: {{ name }}-{{ chaincode_name }}-{{ chaincode.version }}
  namespace: {{ chaincode_ns }}
  annotations:
    fluxcd.io/automated: "false"
spec:
  interval: 1m
  releaseName: {{ name }}-{{ chaincode_name }}-{{ chaincode.version }}
  chart:
    spec:
      interval: 1m
      sourceRef:
        kind: GitRepository
        name: flux-{{ network.env.type }}
        namespace: flux-{{ network.env.type }}
      chart: {{ charts_dir }}/external_chaincode  
  values:
    metadata:
      namespace: {{ chaincode_ns }}
      network:
        version: {{ network.version }}
      images:
        external_chaincode: {{ chaincode_image }}
        alpineutils: {{ alpine_image }}

    chaincode:
      org: {{ org_name }}
      name: {{ chaincode.name }}
      version: {{ chaincode.version }}
      ccid: {{ ccid.stdout | replace(',','') }} 
      tls: {{ chaincode.tls }}
{% if chaincode.tls == true %}      
      crypto_mount_path: {{ chaincode.crypto_mount_path }}
{% endif %}

    vault:
      role: vault-role
      address: {{ vault.url }}
      authpath: {{ network.env.type }}{{ namespace }}-auth
      chaincodesecretprefix: {{ vault.secret_path | default('secretsv2') }}/data/crypto/peerOrganizations/{{ namespace }}/chaincodes/{{ chaincode.name }}/certificate/v{{ chaincode.version }}
      serviceaccountname: vault-auth
{% if chaincode.private_registry is not defined or chaincode.private_registry == false %}   
      imagesecretname: regcred
{% endif %}
{% if chaincode.private_registry is defined and chaincode.private_registry == true %}   
      imagesecretname: chaincode-private-regcred
{% endif %}
    service:
      servicetype: ClusterIP
