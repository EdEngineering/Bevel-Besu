[//]: # (##############################################################################################)
[//]: # (Copyright Accenture. All Rights Reserved.)
[//]: # (SPDX-License-Identifier: Apache-2.0)
[//]: # (##############################################################################################)

## ROLE: create/new_orderer/create_syschannel_block
This role creates the update_channel.sh script for modifying the latest configuration block and adding new orderer tls certificate and endpoint in the config block.

### Tasks
(Variables with * are fetched from the playbook which is calling this role)

#### 1. Wait for the orderer pod
This waits untill the ordrer pods are up
##### Input Variables
    *orderer_namespace: namespace of the orderer organization
    *orderer_kubeconfig: kubernetes configuration file for the orderer organization
    *orderer_context: kubernetes context of the orderer organization
**include_tasks**: It includes the name of intermediatory task which is required for creating the vault auth value file.
**loop**: loops over result list fetched from *network.organizaions*
**loop_control**: Specify conditions for controlling the loop.
    
    loop_var: loop variable used for iterating the loop.

**when**: specifies the condition when the *ordererorg.type* is *orderer* and *update_type* is *address*

#### 2. Ensure channel-artifacts dir exists
This tasks ensures whether the channel-artifacts dir exists

#### 3. Remove the old orderer file if generated in previous step
This task deletes the old orderer file if exists.
##### Input Variables

    *build_path: The path of build directory.
    *channel_name: The name of the channel.

  
#### 4. Creating new orderer file
This task touches the orderer file.
##### Input Variables

    *build_path: The path of build directory.
    *channel_name: The name of the channel.

#### 5. Adding tls certificate information
This task loops over the orderers and add their information if they are new to the network
##### Input Variables
    *build_path: The path of build directory.
    *org: The information of the organization.
    *orderer: The orderer information.
**loop**: loops over *orderers* of the orderer organization
**loop_control**: Specify conditions for controlling the loop.
    
     loop_var: loop variable used for iterating the loop.

**when**: specifies the condition when the *update_type* is *tls*

#### 6. Adding new endpoint information
This task loops over the orderers and add their information if they are new to the network
##### Input Variables
    *build_path: The path of build directory.
    *org: The information of the organization.
    *orderer: The orderer information.
**loop**: loops over *orderers* of the orderer organization
**loop_control**: Specify conditions for controlling the loop.
    
     loop_var: loop variable used for iterating the loop.

**when**: specifies the condition when the *update_type* is *address*

#### 7. Adding information to orderer file
This task creates a json array for the information in the orderer file

#### 8. Create create-syschannel-block.sh script file for new orderer
This task creates the create_block.sh script
##### Input Variables
    *component_name: The name of resource
    *component_ns: The namespace of resourse
    *os: The operating system for the platform
    *arch: The platform architecture
    *version: The network version
**template** : It contains the source and destinations details required for value file generation of access policy.
**src**: Contains the details of template file.
**dest**: Destination path and name of file to be generated.
**when**: Condition is specified here, runs only when the *update_type* is *tls*.

#### 9. Create create-syschannel-block.sh script file for new orderer
This task creates the create_block.sh script
##### Input Variables
    *component_name: The name of resource
    *component_ns: The namespace of resourse
    *os: The operating system for the platform
    *arch: The platform architecture
    *version: The network version
**template** : It contains the source and destinations details required for value file generation of access policy.
**src**: Contains the details of template file.
**dest**: Destination path and name of file to be generated.
**when**: Condition is specified here, runs only when the *update_type* is *address*.

#### 10. Call nested_create_cli for the first orderer
This task calls nested_create_cli for the first orderer
##### Input Variables
    *orderer: The information of the first orderer in orderer organization

**include_tasks**: It includes the name of intermediatory task which is required for creating the vault auth value file.

#### 11. Create genesis block
This task creates the genesis block by consuming the latest config block
##### Input Variables

    *channel_name: The name of the system channel.
**when**: Condition is specified here, runs only when the *update_type* is *address*.

#### 12. Write genesis block to Vault
Writes the BASE64 encoded genesis block to the Vault path of the orderer organizations.
**shell**: Executes a `vault cli` command to write the BASE 64 encoded genesis block to the Vault.

------------
### nested_create_cli.yaml
This task initiates the nested role for creating, fetching and modifying the config block

### Tasks

#### 1. create valuefile for cli {{ orderer.name }}-{{ org.name }}-{{ channel_name }}
This task create the value file for creater org first peer.
##### Input Variables

    *component_type_name: The orderer organization name 
    *orderer_name: Name of the orderer
    *component_ns: The namespace of the organization
    *charts_dir: Path to the charts directory
    *vault: The information of the vault
    *channel_name: Name of the channel
    *storage_class: Name of the storage class to be used for cli
    *release_dir: The path to the release directory
    *orderer_address: Address of the orderer

#### 2. start cli 
This task starts the cli using the value file created in the previous stepr.
##### Input Variables

    *build_path: The path of build directory.
    *config_file: Kubernetes file
    *playbook_dir: Path for the playbook directory
    *chart_source: Path for the charts directory 

  
#### 3. waiting for the fabric cli
This task wait for the fabric cli generated in the previous step to get into running state.
##### Input Variables

    namespace: Namespace of the organization
    kubeconfig: kubeconfig file
##### Output Variables
    get_cli: This variable stores the output of check if fabric cli is present query.

#### 4. fetch, modify, update and copy the configuration block from the blockchain
This task fetch, modify, update and copy the configuration block from the blockchain with the new orderer information.
##### Input Variables

    *config_file: Kubernetes file
    *kubernetes: Kubernetes cluster information of the organization

#### 5. fetch the latest configuration block from the blockchain
This task fetch the latest configuration block from the blockchain to be used as genesis block.
##### Input Variables

    *config_file: Kubernetes file
    *kubernetes: Kubernetes cluster information of the organization