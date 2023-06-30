[//]: # (##############################################################################################)
[//]: # (Copyright Accenture. All Rights Reserved.)
[//]: # (SPDX-License-Identifier: Apache-2.0)
[//]: # (##############################################################################################)

## ROLE: create/certificates/node
This role downloads certificates from nms and loads into vault. Certificates are created using openssl.

### Tasks
(Variables with * are fetched from the playbook which is calling this role)
#### 1. Ensure build dir exists
This tasks checks if the build directory where node certificates and key will be placed already created or not.
##### Input Variables

    path: The path to the directory is specified here.
    recurse: Yes/No to recursively check inside the path specified.

#### 2. Check if truststore already created
This tasks checks if the truststore already created or not.

##### Input Variables
    *VAULT_ADDR: Contains Vault URL, Fetched using 'vault.' from network.yaml
    *VAULT_TOKEN: Contains Vault Token, Fetched using 'vault.' from network.yaml
    component_name: The name of node resource

##### Output Variables

    truststore_result: This variable stores the output of write networkmapstore to vault query.

#### 3. Downloads certs from nms
This tasks downloads the certificates from NMS.
##### Input Variables

    url: path to nms truststore
    dest: path to metwork-map-truststore.jks
    validate_certs: whether to validate the jks file or not.

**when**:  It runs when *truststore_result.failed* == True, i.e. truststore is present . 

#### 4.Downloads certs from NMS pod
This tasks downloads the certificates from NMS pod.
#### Input Variables

    nms_namespace: nms_namespace is service namespace
    nms_name:  name of the service, nms, that comes from network.yaml.

**when**: truststore_result.failed == True and network.env.proxy == 'none' i.e trusrstore is present and network.env.proxy == 'none'.

#### 5. Write networkmaptruststore to vault
This task loads the certificates to vault.
##### Input Variables

    *VAULT_ADDR: Contains Vault URL, Fetched using 'vault.' from network.yaml
    *VAULT_TOKEN: Contains Vault Token, Fetched using 'vault.' from network.yaml
    component_name: The name of node resource


#### 6. Check if certificates already created
This task check if certificates already created

##### Input Variables
    *VAULT_ADDR: Contains Vault URL, Fetched using 'vault.' from network.yaml
    *VAULT_TOKEN: Contains Vault Token, Fetched using 'vault.' from network.yaml
    component_name: The name of node resource
    ignore_errors: Ignore ifany error occurs

**shell**: It fetches customnodekeystore from vault.

##### Output Variables

    certs_result: This variable stores the output of node customnodekeystore check query.

#### 7. Generate node certs
This task generates node certificates using openssl

##### Input Variables
    node_certs: Path to node certificates
    component_name: The name of node resource

**shell**: It generates {{ component_name }}.cer, {{ component_name }}.key and  testkeystore.p12 file in the node_certs directory.
**when**:  It runs when *certs_result.failed* == True, i.e. node certs are not present .


#### 8. Write certificates to vault
This task puts certs in vault.

##### Input Variables
    node_certs: Path to node certificate directory
    component_name: The name of node resource

**shell**: It generates nodekeystore.key and cordarootca.pem file in the rootca directory.
**when**:  It runs when *certs_result.failed* == True and *rootca_stat_result.stat.exists* == False, i.e. root certs are not present and root key.jks is also not present.

#### 9.  Check if doorman certs already created.
This task checks whether the doorman certs already created or not

##### Input Variables
    *VAULT_ADDR: Contains Vault URL, Fetched using 'vault.' from network.yaml
    *VAULT_TOKEN: Contains Vault Token, Fetched using 'vault.' from network.yaml
    component_name: The name of node resource
    ignore_errors: Ignore ifany error occurs

**shell**: It fetches doorman.crt from vault.

##### Output Variables

    doorman_result: This variable stores the output of doorman certificates check query.

#### 10. Write certificates to vault.
This tasks writes doorman certificates to Vault.
##### Input Variables
    doorman_cert_file: Doorman certificate file.
    component_name: The name of node resource

**when**:  It runs when *doorman_result.failed* == True and *doorman_cert_file* != '' i.e. doorman certs are not present and doorman certificate file is not empty . 

#### 11. Check if networkmap certs already created
This task checks whether the nms certs already created or not

##### Input Variables
    *VAULT_ADDR: Contains Vault URL, Fetched using 'vault.' from network.yaml
    *VAULT_TOKEN: Contains Vault Token, Fetched using 'vault.' from network.yaml
    component_name: The name of node resource
    ignore_errors: Ignore ifany error occurs

**shell**: It fetches networkmap.jks from vault.

##### Output Variables

    networkmap_result: This variable stores the output of nms certificates check query.

#### 12. Write certificates to vault
This task generates the networkmap certificates.

##### Input Variables
    nms_cert_file: Networkmap certificate file.
    component_name: The name of node resource

**when**:  It runs when *networkmap_result.failed* == True, i.e. nms certs are not present . 

#### 13. Write credentials to vault
This task writes the database, rpcusers, keystore and networkmappassword credentials in Vault.

##### Input Variables
    *VAULT_ADDR: Contains Vault URL, Fetched using 'vault.' from network.yaml
    *VAULT_TOKEN: Contains Vault Token, Fetched using 'vault.' from network.yaml
    component_name: The name of node resource

**shell**:  It writes the database, rpcusers, keystore and networkmappassword credentials in Vault .

#### 13. Write cordapps credentials to vault
This task writes the corapps repository userpass credentials in Vault.

##### Input Variables
    *VAULT_ADDR: Contains Vault URL, Fetched using 'vault.' from network.yaml
    *VAULT_TOKEN: Contains Vault Token, Fetched using 'vault.' from network.yaml
    component_name: The name of node resource

**shell**:  It writes the credentials in Vault .

**when**:  It runs when *cordapps_details* != "", i.e. cordapps repository details are provided in the configuration file . 

#### 14. Create the Ambassador certificates
This task creates the Ambassador certificates by calling create/certificates/ambassador role.

#### Note:
vars folder has enviornment variable for node role.
