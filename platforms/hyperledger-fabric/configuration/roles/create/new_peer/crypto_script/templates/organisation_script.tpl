#!/bin/bash

set -x

CURRENT_DIR=${PWD}
FULLY_QUALIFIED_ORG_NAME="{{ component_ns }}"
ALTERNATIVE_ORG_NAMES=("{{ component_ns }}.svc.cluster.local" "{{ component_name }}.net" "{{ component_ns }}.{{ item.external_url_suffix }}")
ORG_NAME="{{ component_name }}"
EXTERNAL_URL_SUFFIX="{{ item.external_url_suffix }}"
AFFILIATION="{{ component_name }}"
SUBJECT="C={{ component_country }},ST={{ component_state }},L={{ component_location }},O={{ component_name }}"
SUBJECT_PEER="{{ component_subject }}"
CA="{{ ca_url }}"
CA_ADMIN_USER="${ORG_NAME}-admin"
CA_ADMIN_PASS="${ORG_NAME}-adminpw"

ORG_ADMIN_USER="Admin@${FULLY_QUALIFIED_ORG_NAME}"
ORG_ADMIN_PASS="Admin@${FULLY_QUALIFIED_ORG_NAME}-pw"

ORG_CYPTO_FOLDER="/crypto-config/peerOrganizations/${FULLY_QUALIFIED_ORG_NAME}"

ROOT_TLS_CERT="/crypto-config/peerOrganizations/${FULLY_QUALIFIED_ORG_NAME}/ca/ca.${FULLY_QUALIFIED_ORG_NAME}-cert.pem"

CAS_FOLDER="${HOME}/ca-tools/cas/ca-${ORG_NAME}"
ORG_HOME="${HOME}/ca-tools/${ORG_NAME}"

NO_OF_PEERS={{ peer_count | e }}
NO_OF_NEW_PEERS={{ new_peer_count | e }}

## Enroll CA administrator for Org. This user will be used to create other identities
fabric-ca-client enroll -d -u https://${CA_ADMIN_USER}:${CA_ADMIN_PASS}@${CA} --tls.certfiles  ${ROOT_TLS_CERT} --home ${CAS_FOLDER}  --csr.names "${SUBJECT_PEER}"

## Get the CA cert and store in Org MSP folder
fabric-ca-client getcacert -d -u https://${CA} --tls.certfiles ${ROOT_TLS_CERT} -M ${ORG_CYPTO_FOLDER}/msp

if [ "{{ proxy }}" != "none" ]; then
	mv ${ORG_CYPTO_FOLDER}/msp/cacerts/*.pem ${ORG_CYPTO_FOLDER}/msp/cacerts/ca-${FULLY_QUALIFIED_ORG_NAME}-${EXTERNAL_URL_SUFFIX}-8443.pem
fi
mkdir ${ORG_CYPTO_FOLDER}/msp/tlscacerts
cp ${ORG_CYPTO_FOLDER}/msp/cacerts/* ${ORG_CYPTO_FOLDER}/msp/tlscacerts

## Enroll admin for Org and populate admincerts for MSP
fabric-ca-client enroll -d -u https://${ORG_ADMIN_USER}:${ORG_ADMIN_PASS}@${CA} --id.affiliation ${AFFILIATION} --tls.certfiles ${ROOT_TLS_CERT} --home ${ORG_HOME}/admin  --csr.names "${SUBJECT_PEER}"

# Copy existing org certs
mkdir -p ${ORG_CYPTO_FOLDER}/msp/admincerts
cp ${ORG_HOME}/admin/msp/signcerts/* ${ORG_CYPTO_FOLDER}/msp/admincerts/${ORG_ADMIN_USER}-cert.pem

mkdir -p ${ORG_HOME}/admin/msp/admincerts
cp ${ORG_HOME}/admin/msp/signcerts/* ${ORG_HOME}/admin/msp/admincerts/${ORG_ADMIN_USER}-cert.pem

mkdir -p ${ORG_CYPTO_FOLDER}/users/${ORG_ADMIN_USER}
cp -R ${ORG_HOME}/admin/msp ${ORG_CYPTO_FOLDER}/users/${ORG_ADMIN_USER}

if [ "{{ proxy }}" != "none" ]; then
	mv ${ORG_CYPTO_FOLDER}/users/${ORG_ADMIN_USER}/msp/cacerts/*.pem ${ORG_CYPTO_FOLDER}/users/${ORG_ADMIN_USER}/msp/cacerts/ca-${FULLY_QUALIFIED_ORG_NAME}-${EXTERNAL_URL_SUFFIX}-8443.pem
fi

# Get TLS cert for admin and copy to appropriate location
fabric-ca-client enroll -d --enrollment.profile tls -u https://${ORG_ADMIN_USER}:${ORG_ADMIN_PASS}@${CA} -M ${ORG_HOME}/admin/tls --tls.certfiles ${ROOT_TLS_CERT} --csr.names "${SUBJECT_PEER}"

# Copy the TLS key and cert to the appropriate place
mkdir -p ${ORG_CYPTO_FOLDER}/users/${ORG_ADMIN_USER}/tls
cp ${ORG_HOME}/admin/tls/keystore/* ${ORG_CYPTO_FOLDER}/users/${ORG_ADMIN_USER}/tls/client.key
cp ${ORG_HOME}/admin/tls/signcerts/* ${ORG_CYPTO_FOLDER}/users/${ORG_ADMIN_USER}/tls/client.crt
cp ${ORG_HOME}/admin/tls/tlscacerts/* ${ORG_CYPTO_FOLDER}/users/${ORG_ADMIN_USER}/tls/ca.crt

## Register and enroll peers and populate their MSP folder
COUNTER=`expr ${NO_OF_PEERS} - ${NO_OF_NEW_PEERS}`
while [  ${COUNTER} -lt ${NO_OF_PEERS} ]; do
	PEER="peer${COUNTER}.${FULLY_QUALIFIED_ORG_NAME}"
	CSR_HOSTS=${PEER}
	for i in "${ALTERNATIVE_ORG_NAMES[@]}"
	do
		CSR_HOSTS="${CSR_HOSTS},peer${COUNTER}.${i}"
	done
	echo "Registering and enrolling $PEER with csr hosts ${CSR_HOSTS}"

	# Register the peer
	fabric-ca-client register -d --id.name ${PEER} --id.secret ${PEER}-pw --id.type peer --tls.certfiles ${ROOT_TLS_CERT} --home ${CAS_FOLDER} -u https://${CA}

	# Enroll to get peers TLS cert
	fabric-ca-client enroll -d --enrollment.profile tls -u https://${PEER}:${PEER}-pw@${CA} -M ${ORG_HOME}/cas/peers/tls --csr.hosts "${CSR_HOSTS}" --tls.certfiles ${ROOT_TLS_CERT}  --csr.names "${SUBJECT_PEER}"

	# Copy the TLS key and cert to the appropriate place
	mkdir -p ${ORG_CYPTO_FOLDER}/peers/${PEER}/tls
	cp ${ORG_HOME}/cas/peers/tls/keystore/* ${ORG_CYPTO_FOLDER}/peers/${PEER}/tls/server.key	
	cp ${ORG_HOME}/cas/peers/tls/signcerts/* ${ORG_CYPTO_FOLDER}/peers/${PEER}/tls/server.crt	
	cp ${ORG_HOME}/cas/peers/tls/tlscacerts/* ${ORG_CYPTO_FOLDER}/peers/${PEER}/tls/ca.crt
	
	rm -rf ${ORG_HOME}/cas/peers/tls
	
	# Enroll again to get the peer's enrollment certificate (default profile)
	fabric-ca-client enroll -d -u https://${PEER}:${PEER}-pw@${CA} -M ${ORG_CYPTO_FOLDER}/peers/${PEER}/msp --tls.certfiles ${ROOT_TLS_CERT}  --csr.names "${SUBJECT_PEER}"

	# Create the TLS CA directories of the MSP folder if they don't exist.
	mkdir -p ${ORG_CYPTO_FOLDER}/peers/${PEER}/msp/tlscacerts	
	
	# Copy the peer org's admin cert into target MSP directory
	mkdir -p ${ORG_CYPTO_FOLDER}/peers/${PEER}/msp/admincerts
	if [ "{{ proxy }}" != "none" ]; then
		mv ${ORG_CYPTO_FOLDER}/peers/${PEER}/msp/cacerts/*.pem ${ORG_CYPTO_FOLDER}/peers/${PEER}/msp/cacerts/ca-${FULLY_QUALIFIED_ORG_NAME}-${EXTERNAL_URL_SUFFIX}-8443.pem
	fi
	cp ${ORG_CYPTO_FOLDER}/peers/${PEER}/msp/cacerts/* ${ORG_CYPTO_FOLDER}/peers/${PEER}/msp/tlscacerts
	cp ${ORG_CYPTO_FOLDER}/msp/admincerts/${ORG_ADMIN_USER}-cert.pem ${ORG_CYPTO_FOLDER}/peers/${PEER}/msp/admincerts
	
	let COUNTER=COUNTER+1
done

cd ${CURRENT_DIR}
