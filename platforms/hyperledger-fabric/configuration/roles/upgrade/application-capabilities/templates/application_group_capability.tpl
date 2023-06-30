#!/bin/bash

set -x

CURRENT_DIR=${PWD}

echo "installing jq "
apt-get install -y jq
echo "installing configtxlator"
mkdir temp
cd temp/
wget https://github.com/hyperledger/fabric/releases/download/v{{ version }}/hyperledger-fabric-{{ os }}-{{ arch }}-{{ version }}.tar.gz
tar -xvf hyperledger-fabric-{{ os }}-{{ arch }}-{{ version }}.tar.gz
mv bin/configtxlator ../
cd ../
rm -r temp

configtxlator proto_decode --input {{ channel_name }}_config_block.pb --type common.Block | jq .data.data[0].payload.data.config > {{ channel_name }}_config_block.json

jq -s '.[0] * {"channel_group":{"groups":{"Application": {"values": {"Capabilities": { "value": .[1].application.value }}}}}}' {{ channel_name }}_config_block.json ./capabilities.json > modified_config.json
echo "copy existing channel config and modified channel config"
cp {{ channel_name }}_config_block.json config_orig.json
cp modified_config.json config_modified.json
echo "converting the channel_config.json and channel_modified_config.json to .pb files"
configtxlator proto_encode --input {{ channel_name }}_config_block.json --type common.Config --output {{ channel_name }}_config.pb
configtxlator proto_encode --input modified_config.json --type common.Config --output {{ channel_name }}_updated_config.pb
echo "calculate the delta between these two config protobufs using configtxlator"
configtxlator compute_update --channel_id {{ channel_name }} --original {{ channel_name }}_config.pb --updated {{ channel_name }}_updated_config.pb --output {{ channel_name }}_diff_config.pb
echo "decode the channel_update.pb to json to add headers."
configtxlator proto_decode --input {{ channel_name }}_diff_config.pb --type common.ConfigUpdate | jq . > {{ channel_name }}_diff_config.json
echo "wrapping the headers arround the channel_update.json file and create channel_update_in_envelope.json"
echo '{"payload":{"header":{"channel_header":{"channel_id":"{{ channel_name }}", "type":2}},"data":{"config_update":'$(cat {{ channel_name }}_diff_config.json)'}}}' | jq . > {{ channel_name }}_diff_config_envelope.json
echo "converting the channel_update_in_envelope.json to channel_update_in_envelope.pb"
configtxlator proto_encode --input {{ channel_name }}_diff_config_envelope.json --type common.Envelope --output {{ channel_name }}_update_in_envelope.pb
mv {{ channel_name }}_config_block.pb {{ channel_name }}_config_block_old.pb
cd ${CURRENT_DIR}
