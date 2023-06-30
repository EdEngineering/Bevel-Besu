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
    chart: {{ charts_dir }}/gateway
    sourceRef:
      kind: GitRepository
      name: flux-{{ network.env.type }}
      namespace: flux-{{ network.env.type }}
  values:
    nodeName: {{ component_name }}
    metadata:
      namespace: {{ component_ns }}
      labels:
    prefix: {{ org.name }}
    image:
      initContainerName: {{ network.docker.url }}/{{ init_container_image }}
      gatewayContainerName: {{ main_container_image }}
      imagePullSecrets:
        - name: "regcred"
      pullPolicy: IfNotPresent
    cenmServices:
      idmanName: {{ org.services.idman.name }}
      zoneName: {{ org.services.zone.name }}
      zonePort: {{ org.services.zone.ports.admin }}
      gatewayPort: {{ org.services.gateway.ports.servicePort }}
      authName: {{ org.services.auth.name }}
      authPort: {{ org.services.auth.port }}
    storage:
      name: cordaentsc
    acceptLicense: YES
    vault:
      address: {{ vault.url }}
      role: vault-role
      authPath: {{ component_auth }}
      serviceAccountName: vault-auth
      certSecretPrefix: {{ vault.secret_path | default('secretsv2') }}/data/{{ org.name | lower }}
      retries: 10
      sleepTimeAfterError: 15
    config:
      volume:
        baseDir: /opt/cenm
      jarPath: bin
      configPath: etc
      pvc:
        volumeSizeGatewayEtc: 1Gi
        volumeSizeGatewayLogs: 5Gi
      pod:
        resources:
          limits:
            memory: 2Gi
          requests:
            memory: 2Gi
      replicas: 1
    service:
      type: ClusterIP
      port: 8080
    ambassador:
      external_url_suffix: "{{ org.external_url_suffix }}"
      port: {{ org.services.gateway.ports.ambassadorPort }}
