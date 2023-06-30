[//]: # (##############################################################################################)
[//]: # (Copyright Accenture. All Rights Reserved.)
[//]: # (SPDX-License-Identifier: Apache-2.0)
[//]: # (##############################################################################################)

## ROLE: peers
This role creates the helm value file for peers of organisations and write couch db credentials to the vault.

### Tasks
(Variables with * are fetched from the playbook which is calling this role)
#### 1. Reset peers pods
This task reset peers pods
##### Input Variables
    *pod_name: Provide the name of the pod
    *name: Provide the name of the organization
    *file_path: Provide the release file path
    *gitops_value: *item.gitops* from network.yaml
    *component_ns: Provide the namespace of the resource
    *kubernetes: *item.k8s* from network.yaml
    *hr_name: Provides the name of the helmrealse
**when**: It runs Only when *refresh_cert* is defined and *refresh_cert* is true.

#### 2. Create Value files for Organization Peers
This task is the nested task for main.yaml which helps to iterate over all peers.
##### Input Variables

    *name: Name of the item
    *peer_name: The name of the peer
    *peer_ns: Namespace of the peer
    *component_name: "The name of the component"
    type: "value_peer"
**include_role**: It includes the name of intermediatory role which is required for creating the helm value file, here helm_component
**loop**: loops over peers list fetched using *{{ component_services.peers }}* from network yaml
**loop_control**: Specify conditions for controlling the loop.
                
    loop_var: loop variable used for iterating the loop.

#### 3. Git Push
This task pushes the above generated value files to git repo.
##### Input Variables
    GIT_DIR: "The path of directory which needs to be pushed"    
    GIT_RESET_PATH: "This variable contains the path which wont be synced with the git repo"
    gitops: *item.gitops* from network.yaml
    msg: "Message for git commit"

**include_role**: It includes the name of intermediatory role which is required for creating the vault auth value file.

#### 4. Check peer pod is up
This tasks check if the namespace is already created or not.
##### Input Variables

    kind: This defines the kind of Kubernetes resource
    *name: Name of the component 
    *namespace: Namespace of the component
    *kubeconfig: The config file of the cluster
    *context: This refer to the required kubernetes cluster context
    *org_query: Query to get peer names for organisations
    *peer_name: Name of the peer
    
**include_role**: It includes the name of intermediatory role which is required for creating the vault auth value file.
