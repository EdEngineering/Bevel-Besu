[//]: # (##############################################################################################)
[//]: # (Copyright Accenture. All Rights Reserved.)
[//]: # (SPDX-License-Identifier: Apache-2.0)
[//]: # (##############################################################################################)

<a name = "deploy-generate-ambassador-certs"></a>
# Ambassador Certs Hyperledger Besu Deployment

- [Ambassador Certs Hyperledger Besu Deployment Helm Chart](#ambassador-certs-hyperledger-besu-deployment-helm-chart)
- [Prerequisites](#prerequisites)
- [Chart Structure](#chart-structure)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [Verification](#verification)
- [Updating the Deployment](#updating-the-deployment)
- [Deletion](#deletion)
- [Contributing](#contributing)
- [License](#license)


<a name = "ambassador-certs-hyperledger-besu-deployment-helm-chart"></a>
## Ambassador Certs Hyperledger Besu Deployment Helm Chart
---
This [Helm chart](https://github.com/hyperledger/bevel/blob/develop/platforms/hyperledger-besu/charts/generate_ambassador_certs) facilitates the deployment of Ambassador certificates using Kubernetes Jobs and stores them securely in HashiCorp Vault.


<a name = "prerequisites"></a>
## Prerequisites
---
Before deploying the Helm chart, make sure to have the following prerequisites:

- Kubernetes cluster up and running.
- The Besu network is set up and running.
- A HashiCorp Vault instance is set up and configured to use Kubernetes service account token-based authentication.
- The Vault is unsealed and initialized.
- Helm installed.


<a name = "chart-structure"></a>
## Chart Structure
---
The structure of the Helm chart is as follows:

```
generate_ambassador_certs/
  |- templates/
      |- _helpers.yaml
      |- job.yaml
  |- Chart.yaml
  |- README.md
  |- values.yaml
```

- `templates/`: This directory contains the Kubernetes manifest templates that define the resources to be deployed.
- `helpers.tpl`: Contains custom label definitions used in other templates.
- `job.yaml`: This file defines the Kubernetes Job resource for generating ambassador certificates and storing them in the Hashicorp Vault.
- `Chart.yaml`: This file contains the metadata for the Helm chart, such as the name, version, and description.
- `README.md`: This file provides information and instructions about the Helm chart.
- `values.yaml`: This file contains the default configuration values for the Helm chart.


<a name = "configuration"></a>
## Configuration
---
The [values.yaml](https://github.com/hyperledger/bevel/blob/develop/platforms/hyperledger-besu/charts/generate_ambassador_certs/values.yaml) file contains configurable values for the Helm chart. We can modify these values according to the deployment requirements. Here are some important configuration options:

## Parameters
---

### Metadata

| Name            | Description                                                                  | Default Value |
| ----------------| ---------------------------------------------------------------------------- | ------------- |
| namespace       | Provide the namespace                                                  | default       |
| name            | Provide the name for besu-ambassador-certs job release                 | besu-ambassador-certs            |

### Image

| Name                     | Description                                                                                | Default Value   |
| ------------------------ | -------------------------------------------------------                                    | --------------- |
| alpineutils        | Provide the alpine utils image, which is used by all containers of this job  | ghcr.io/hyperledger/bevel-alpine:latest              |
| imagePullSecret          | Provide the docker-registry secret created and stored in kubernetes cluster as a secret    | regcred         |
| pullPolicy               | Pull policy to be used for the Docker image                                                | IfNotPresent    |

### Network
| Name                     | Description                                                                                | Default Value   |
| ------------------------ | -------------------------------------------------------                                    | --------------- |
| tmtls               | Provide the value from tm_tls. This enables TLS for the transaction manager and Besu node.                 | True |

### Node

| Name                     | Description                                                                                | Default Value   |
| ------------------------ | -------------------------------------------------------                                    | --------------- |
| name               | Provide the name of the node.                 | node1   |
| clientport         | Provide tm client ports               | 8888   |


### Vault

| Name                      | Description                                                               | Default Value |
| ------------------------- | --------------------------------------------------------------------------| ------------- |
| address                   | Address/URL of the Vault server.                                          | ""            |
| secretengine              | Provide the secret engine.                                                | secretsv2     |
| authpath                  | Authentication path for Vault                                             | besunode1  |
| rootcasecret              | Provide the vault path where the root certificates are stored                  | ""           |
| ambassadortlssecret       | Provide the vault path where the ambassador certificates are stored                  | ""            |
| role                      | Role used for authentication with Vault                                   | vault-role    |
| serviceAccountName        | Provide the already created service account name autheticated to vault    | vault-auth    |
| type        | Provide the type of vault    | hashicorp    |

### Subjects

| Name                      | Description                        | Default Value |
| ------------------------- | ---------------------------------- | ------------- |
| ambassadortls             | Mention the subject for ambassador tls       | ""            |

### OpenSSL Vars

| Name                      | Description                                              | Default Value |
| --------------------------| ----------------------------------------------------------| ------------- |
| domain_name_pub           | Provides the name for public domain                       | ""            |
| domain_name_priv          | Provides the name for private domain                      | ""            |
| domain_name_tessera       | provides the name for domain domain_name tessera endpoint | ""            |


### Healthcheck


| Name                        | Description                                                                   | Default Value |
| ----------------------------| ------------------------------------------------------------------------------| ------------- |
| retries                     |  Provide the threshold number of retries in fetching certificates from vault      | 10             |
| sleepTimeAfterError         | Provide the wait interval in seconds in fetching certificates from vault   | 2             |

<a name = "deployment"></a>
## Deployment
---

To deploy the generate_ambassador_certs Helm chart, follow these steps:

1. Modify the [values.yaml](https://github.com/hyperledger/bevel/blob/develop/platforms/hyperledger-besu/charts/generate_ambassador_certs/values.yaml) file to set the desired configuration values.
2. Run the following Helm command to install the chart:
    ```
    $ helm repo add bevel https://hyperledger.github.io/bevel/
    $ helm install <release-name> ./generate_ambassador_certs
    ```
Replace `<release-name>` with the desired name for the release.

This will deploy the ambassador certs job to the Kubernetes cluster based on the provided configurations.

<a name = "verification"></a>
## Verification
---

To verify the deployment, we can use the following command:
```
$ kubectl get jobs -n <namespace>
```
Replace `<namespace>` with the actual namespace where the deployment was created. The command will display information about the deployment, including the number of 
replicas and their current status.

<a name = "updating-the-deployment"></a>
## Updating the Deployment
---

If we need to update the deployment with new configurations or changes, modify the same [values.yaml](https://github.com/hyperledger/bevel/blob/develop/platforms/hyperledger-besu/charts/generate_ambassador_certs/values.yaml) file with the desired changes and run the following Helm command:
```
$ helm upgrade <release-name> ./generate_ambassador_certs
```
Replace `<release-name>` with the name of the release. This command will apply the changes to the deployment, ensuring the generate_ambassador_certs node is up to date.

<a name = "deletion"></a>
## Deletion
---

To delete the deployment and associated resources, run the following Helm command:
```
$ helm uninstall <release-name>
```
Replace `<release-name>` with the name of the release. This command will remove all the resources created by the Helm chart.

<a name = "contributing"></a>
## Contributing
---
If you encounter any bugs, have suggestions, or would like to contribute to the [Ambassador Certs GoQuorum Deployment Helm Chart](ttps://github.com/hyperledger/bevel/blob/develop/platforms/hyperledger-besu/charts/generate_ambassador_certs), please feel free to open an issue or submit a pull request on the [project's GitHub repository](https://github.com/hyperledger/bevel).

<a name = "license"></a>
## License

This chart is licensed under the Apache v2.0 license.

Copyright &copy; 2023 Accenture

### Attribution

This chart is adapted from the [charts](https://hyperledger.github.io/bevel/) which is licensed under the Apache v2.0 License which is reproduced here:

```
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
