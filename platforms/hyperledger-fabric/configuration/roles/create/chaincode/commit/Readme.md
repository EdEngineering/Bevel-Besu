[//]: # (##############################################################################################)
[//]: # (Copyright Accenture. All Rights Reserved.)
[//]: # (SPDX-License-Identifier: Apache-2.0)
[//]: # (##############################################################################################)


## chaincode/commit
This role creates helm value file for the deployment of chaincode_commit job
### main.yaml
### Tasks
(Variables with * are fetched from the playbook which is calling this role)
#### 1. Create value file for chaincode commit
This task creates value file for chaincode commit.
##### Input Variables

    channelcreator_query:  query based on type, "participants[?type=='creator']"
    org_query: query based on name "organizations[?name=='{{ participant.name }}']"
    org: query result of org_query"{{ network | json_query(org_query) | first }}"
**include_tasks**: It includes the name of intermediatory nested task which is required for creating the value file, here `valuefile.yaml`.
**loop**: loops over creator participant of the channel
**loop_control**: Specify conditions for controlling the loop.
                
    loop_var: loop variable used for iterating the loop.

-------
### valuefile.yaml
### Tasks
(Variables with * are fetched from the playbook which is calling this role)

#### 1. 'Check/Wait for approve-chaincode job'
This tasks checks/Wait for approve-chaincode job.

##### Input Variables

    component_type: The kind of task i.e. here `Job`
    component_name: Name of join channel job. Format: "approvechaincode-{{ peer.name }}-{{ chaincode.name }}-{{ chaincode.version }}"
    namespace: Namespace of component
    kubernetes: The kubernetes patch from network yaml

##### Output Variables

    component_data: This variable stores the output of approve-chaincode query.
	
  **until**: This condition checks until *component_data.resources* variable exists and is not empty.
  **retries**: No of retries
  **delay**: Specifies the delay between every retry
  
#### 2. Check for commit-chaincode job
This tasks checks if commit-chaincode is already run.

##### Input Variables

    component_type: The kind of task i.e. here `OneTimeJob`
    name: Name of commit chaincode job. Format: commitchaincode-{{ peer.name }}-{{ chaincode.name }}-{{ chaincode.version }}
    namespace: Namespace of component
    kubernetes: The kubernetes patch from network yaml

##### Output Variables

    commit_chaincode: This variable stores the output of install-chaincode query.
#### 3. Set endorsers data
This task initializes the endorsers_org variable to empty array.
#### 4. Get endorsers data
This task sets the endorsers_org variable
**loop**: loops over approvers
**loop_control**: Specify conditions for controlling the loop.
                
    loop_var: loop variable used for iterating the loop.
#### 5. Create endorser certs secret
This task creates the k8s secrets for endorser certs
**loop**: loops over approvers
**loop_control**: Specify conditions for controlling the loop.
                
    loop_var: loop variable used for iterating the loop.
#### 6. Create value file for chaincode commit
This is the nested Task for chaincode commit.
##### Input Variables

    *name: "Name of the organisation"
    type: "commit_chaincode_job"
    *component_name: Name of the component, "commit-{{ org.name | lower }}-{{ peer.name }}-{{item.channel_name|lower}}-{{peer.chaincode.name}}{{peer.chaincode.version}}"
    *namespace: "Namespace of org , Format: {{ org.name |lower }}-net"
    *peer_name: "Name of the peer"
    *peer_address: "Gossip peer Address"    
    *git_url: "Git SSH url"
    *git_branch: "Git Branch Name"
    *charts_dir: "Path of Charts Directory"
    *vault: "Vault Details"
    *component_chaincode: "Chaincode Data"
    *values_dir: "Destination directory"
**include_role**: It includes the name of intermediatory role which is required for creating the helm value file, here `helm_component`.
**when** : It runs when chaincode is defined and is not committed i.e. *commit_chaincode.resources.length* == 0.

#### 7. Git Push
This task pushes the above generated value files to git repo.
##### Input Variables
    GIT_DIR: "The path of directory which needs to be pushed"    
    GIT_RESET_PATH: "This variable contains the path which wont be synced with the git repo"
    gitops: *item.gitops* from network.yaml
    msg: "Message for git commit"
