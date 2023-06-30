apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: {{ component_name }}
  namespace: {{ component_ns }}
  annotations:
    fluxcd.io/automated: "false"
spec:
  releaseName: {{ component_name }}
  interval: 1m
  chart:
   spec:
    chart: {{ charts_dir }}/node-initial-registration
    sourceRef:
      kind: GitRepository
      name: flux-{{ network.env.type }}
      namespace: flux-{{ network.env.type }}
  values:
    nodeName: {{ peer.name | lower }}-registration
    metadata:
      namespace: {{ component_ns }}
      labels: {}
    image:
      initContainerName: {{ network.docker.url }}/{{ init_container_image }}
      nodeContainerName: {{ network.docker.url }}/{{ main_container_image }}
      imagepullsecret: regcred
      pullPolicy: IfNotPresent
    truststorePassword: password
    keystorePassword: password
    acceptLicence: true
    networkServices:
      doormanURL: {{ doorman_url }}
      networkMapURL: {{ networkmap_url }}
      idmanDomain: "{{ doorman_url.split(':')[1] | regex_replace('/', '') }}"
      networkMapDomain: "{{ networkmap_url.split(':')[1] | regex_replace('/', '') }}"
      idmanName: "{{ network | json_query('network_services[?type==`idman`].name') | first }}"
      networkmapName: "{{ network | json_query('network_services[?type==`networkmap`].name') | first }}"
    vault:
      address: {{ org.vault.url }}
{% if org.firewall.enabled == true %}
      floatVaultAddress: {{ org.services.float.vault.url }}
      authpathFloat: cordaent{{ org.name | lower }}float
{% else %}
      floatVaultAddress: ""
      authpathFloat: ""
{% endif %}
      role: vault-role
      authpath: cordaent{{ org.name | lower }}
      serviceaccountname: vault-auth
      certsecretprefix: {{ org.vault.secret_path | default('secretsv2') }}/data/{{ org.name | lower }}/{{ peer.name }}
      nodePath: {{ peer.name | lower }}
      retries: 30
      retryInterval: 30
    firewall:
      enabled: {{ org.firewall.enabled }}
    nodeConf:
      ambassador:
        external_url_suffix: {{ org.external_url_suffix }}
        p2pPort: {{ peer.p2p.ambassador }}
{% if org.firewall.enabled == true %}
        p2pAddress: {{ org.services.float.name }}.{{ org.name | lower }}.{{ org.services.float.external_url_suffix }}:{{ org.services.float.ports.ambassador_p2p_port | default('10002') }}
{% else %}
        p2pAddress: {{ node_name }}.{{ org.external_url_suffix }}:{{ peer.p2p.ambassador | default('10002') }}
{% endif %}
      legalName: "{{ peer.subject }}"
      emailAddress: dev-node@bevel.com
      crlCheckSoftFail: true
      tlsCertCrlDistPoint: ""
      tlsCertCrlIssuer: "{{ network | json_query('network_services[?type==`idman`].crlissuer_subject') | first }}"
      devMode: false
      volume:
        baseDir: /opt/corda
      jarPath: bin
      configPath: etc
      cordaJar:
        memorySize: 1524
        unit: M
      pod:
        resources:
          limits: 1524M
          requests: 1524M
    service:
      p2pPort: {{ peer.p2p.port }}
      p2pAddress: {{ peer.name | lower }}.{{ component_ns }}
      messagingServerPort: {{ peer.p2p.port }}
      ssh:
        enabled: true
        sshdPort: 2222
      rpc:
        port: {{ peer.rpc.port }}
        adminPort: {{ peer.rpcadmin.port }}
        users:
        - name: {{ peer.name | lower }}
          password: {{ peer.name | lower }}P
          permissions: ALL
    dataSourceProperties:
      dataSource:
        user: {{ peer.name | lower }}-db-user
        password: {{ peer.name | lower }}-db-password
        url: "jdbc:h2:tcp://{{ peer.name | lower }}db:9101/persistence;DB_CLOSE_ON_EXIT=FALSE;LOCK_TIMEOUT=10000;WRITE_DELAY=100;AUTO_RECONNECT=TRUE;"
        dataSourceClassName: org.h2.jdbcx.JdbcDataSource
        dbUrl: "{{ node_name }}db"
        dbPort: 9101
      monitoring:
        enabled: true
        port: 8090
      allowDevCorDapps:
        enabled: true
      retries: 20
      retryInterval: 15
    sleepTimeAfterError: 120
    sleepTime: 0
    healthcheck:
      readinesscheckinterval: 10
      readinessthreshold:  15
