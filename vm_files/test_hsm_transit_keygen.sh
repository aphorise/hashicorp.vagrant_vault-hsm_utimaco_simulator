#!/bin/bash
sVAULT_TOKEN=${VAULT_TOKEN}  # // '<insert your token here>'
sVAULT_ADDR=${VAULT_ADDR}  # // 'https://...:8200'
sVTRANSIT_PATH='transit_t2'

func_createengine(){
  # // check to see if Transit is enable if not enable it.
  vault secrets list | grep ${sVTRANSIT_PATH} 2>&1>/dev/null ;
  if [[ $? == 1 ]] ; then
      sERR=$(curl -sw '%{http_code}' -X POST -H "X-Vault-Token: ${sVAULT_TOKEN}" -d '{"type":"transit","description":"","config":{"options":null,"default_lease_ttl":"0s","max_lease_ttl":"0s","force_no_cache":false},"local":false,"seal_wrap":false,"external_entropy_access":true,"options":null}' ${sVAULT_ADDR}/v1/sys/mounts/${sVTRANSIT_PATH}) ;
      if [[ ${sERR} == *"204" ]] ; then sMSG="Activated Transit-Engine: ${sVTRANSIT_PATH}" ; else sMSG="UNABLE to activate: ${sVTRANSIT_PATH}" ; fi ;
  else
    sMSG="Transit-Engine: ${sVTRANSIT_PATH} - ALREADY ACTIVE ???" ;
  fi ;
  echo -e "${sMSG}\n--------\n" ;
}

func_createrng(){
  curl -X POST -H "X-Vault-Token: ${sVAULT_TOKEN}" -d '{"allow_plaintext_backup":true,"exportable":true,"type":"rsa-4096"}' ${sVAULT_ADDR}/v1/${sVTRANSIT_PATH}/keys/${1}
}

func_delengine(){
  curl -X DELETE -H "X-Vault-Token: ${sVAULT_TOKEN}" ${sVAULT_ADDR}/v1/sys/mounts/${sVTRANSIT_PATH}
}

echo -e "#Start\nTransit-Engine READY."
func_createengine
read -p "Press enter to continue"

SECONDS=0
echo "Generating Random Numbers ..."
func_createrng key1 &
func_createrng key2

wait # wait for random number generation to complete.
echo -e "Deletion took: ${SECONDS} seconds.\nDISABLING Trainsit-Engine: ${sVTRANSIT_PATH}"
func_delengine

echo -e "Ende#############\n"
