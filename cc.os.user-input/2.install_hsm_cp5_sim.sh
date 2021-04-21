#!/bin/bash
UUSER='utimaco' ;
UGROUP='utimaco' ;
CRYPTO_INSTALL_PATH='/Software/Linux/x86-64' ;
if [[ ! ${USER_VAGRANT+x} ]] ; then USER_VAGRANT='vagrant' ; fi ; # // default vault (daemon) user.
if [[ ! ${HOME_PATH+x} ]] ; then HOME_PATH=$(getent passwd "$USER_VAGRANT" | cut -d: -f6 ) ; fi ;

# // logger
function pOUT() { printf "$1\n" ; } ;
# // Colourised logger for errors (red)
function pERR()
{	# sMSG=${1/@('ERROR:')/"\e[31mERROR:\e[0m"} ; sMSG=${1/('ERROR:')/"\e[31mERROR:\e[0m"}
	if [[ $1 == "--"* ]] ; then pOUT "\e[31m$1\n\e[0m\n" ;
	else pOUT "\n\e[31m$1\n\e[0m\n" ; fi ;
}

if ! mkdir -p /pkcs11 /etc/utimaco /opt/utimaco/bin /opt/utimaco/etc \
	/opt/utimaco/lib64 /opt/utimaco/hsm/bin /opt/utimaco/hsm/devices \
	/opt/utimaco/hsm/firmware /opt/utimaco/etc/systemd/system ; then
		pERR 'ERROR: Unable to create required: /opt/utimaco/bin paths.' ;
		exit 1 ;
fi ;

chmod 777 /pkcs11 ;

# // deamon user setup
groupadd -r -g 500 ${UGROUP} ;
useradd  -r -g ${UGROUP} -d /opt/utimaco/hsm -s /sbin/nologin ${UUSER} ;
usermod -L ${UUSER} ;

sFIND=$(find -iname crypto*.zip) ;

if [[ ${sFIND} == '' ]] ; then
	pERR 'ERROR: Utimaco CryptoServer CP5 .zip file not found.' ;
	exit 1 ;
else
	sFIND_PATH=${sFIND:2:((${#sFIND}-6))} ;
	if unzip -qq ${sFIND} -d ${sFIND_PATH} ; then
		sPWD=${sFIND_PATH}${CRYPTO_INSTALL_PATH} ;
		cp -R ${sPWD}/Administration/key /opt/utimaco/etc ;
		cp ${sPWD}/Administration/csadm /opt/utimaco/bin ;
		cp ${sPWD}/Crypto_APIs/CXI/bin/cxitool /opt/utimaco/bin ;
		cp ${sPWD}/Crypto_APIs/PKCS11_R2/bin/p11tool2 /opt/utimaco/bin ;
		cp ${sPWD}/Crypto_APIs/PKCS11_R2/lib/libcs_pkcs11_R2.so /opt/utimaco/lib64 ;
		cp ${sPWD}/../Simulator/sim5_linux/bin/bl_sim5 /opt/utimaco/hsm/bin ;
		cp -R ${sPWD}/../Simulator/sim5_linux/devices /opt/utimaco/hsm ;
		chown -R ${UUSER}:${UGROUP} /opt/utimaco/hsm/devices
		find /opt/utimaco -type d -exec chmod 0755 {} \;
		find /opt/utimaco -type f -exec chmod 0644 {} \;
		find /opt/utimaco/hsm/devices -type f -exec chmod 0640 {} \;
		chmod a+x /opt/utimaco/bin/* /opt/utimaco/hsm/bin/* ;
		setcap cap_ipc_lock,cap_net_bind_service+ep /opt/utimaco/hsm/bin/bl_sim5 ;
		pOUT 'COPIED: HSM CP5 Simulator Files.' ;
	fi ;
fi ;

printf '''[Unit]
Description=Utimaco HSM Simulator
Requires=network-online.target

[Install]
WantedBy=multi-user.target

[Service]
User=utimaco
Type=simple
Environment="SDK_PORT=288"
Environment="SDK_PATH=/opt/utimaco/hsm"
EnvironmentFile=-/etc/sysconfig/utimaco
ExecStart=/opt/utimaco/hsm/bin/bl_sim5 -o -h
# Sandboxing
ProtectSystem=full
ProtectHome=true
PrivateTmp=true
PrivateDevices=true
''' > /opt/utimaco/etc/systemd/system/utimaco_hsm.service ;
cp /opt/utimaco/etc/systemd/system/utimaco_hsm.service /etc/systemd/system ;
systemctl daemon-reload ;
systemctl enable utimaco_hsm.service ;
systemctl start utimaco_hsm.service ;

touch /opt/utimaco/etc/hsm.key ;
PATH=/opt/utimaco/bin:${PATH} ;
printf 'WAITING 5 seconds before getting csadm GetHSMAuthKey.\n' ;
sleep 5 ;
HSM_KEY=$(csadm Dev=localhost GetHSMAuthKey) ;
if ((${#HSM_KEY} > 1500 )) ; then
    printf "${HSM_KEY}" > /opt/utimaco/etc/hsm.key ;
    pOUT 'WRITTEN: /opt/utimaco/etc/hsm.key' ;
fi ;


printf '''
# Default HSM
export CRYPTOSERVER=localhost ;

# Establish Secure HSM Connection
export CS_AUTH_KEYS=/opt/utimaco/etc/hsm.key ;

# Add HSM Admin binaries to path
export PATH=/opt/utimaco/bin:${PATH} ;
''' > /opt/utimaco/etc/bashrc ;

# // add source
if ! grep /opt/utimaco/etc/bashrc ${HOME_PATH}/.bashrc ; then
    printf "\nsource /opt/utimaco/etc/bashrc\n" >> ${HOME_PATH}/.bashrc ;
    pOUT "Set utimaco source in ${HOME_PATH}/.bashrc" ;
fi ;

if ! grep /opt/utimaco/etc/bashrc /root/.bashrc ; then
    printf "\nsource /opt/utimaco/etc/bashrc\n" >> /root/.bashrc ;
    pOUT "Set utimaco source in /root/.bashrc" ;
fi ;


printf '''[Global]
Logging = 4
Logpath = /var/log  #/pkcs11
Logsize = 100mb

KeyStore=/root/plcs_ext_store.sdb
SlotMultiSession = True

# SlotCount = 10 #

[CryptoServer]
Device = localhost

[Slot]
SlotNumber = 3
# KeysExternal = true ; # // doesnt not work with simulator generates:
# // ERROR: external keys not available in CC mode (`pkcs11/cs_pkcs11_R2.log`)
# USR_0000="RSASign=/home/vagrant/MBK1part1.key"
#ADMIN="RSASign=/opt/utimaco/etc/key/ADMIN_CP5.key"
''' > /etc/utimaco/cs_pkcs11_R2.cfg ;


printf '''[Mechanism]
CK_MECHANISM_TYPE = CKM_AES_KEY_GEN

[Key]
CKA_CLASS = CKO_SECRET_KEY
CKA_KEY_TYPE = CKK_AES
CKA_TOKEN = CK_TRUE
CKA_PRIVATE = CK_TRUE
CKA_SENSITIVE = CK_TRUE
CKA_SIGN = CK_FALSE
CKA_ENCRYPT = CK_TRUE
CKA_DECRYPT = CK_TRUE
CKA_VERIFY = CK_FALSE
CKA_WRAP = CK_FALSE
CKA_UNWRAP = CK_FALSE
CKA_VALUE_LEN = 32
CKA_LABEL = "hsm:v1:vault"
CKA_ID = 0x4145848
CKA_EXTRACTABLE = CK_FALSE
''' > aes.key_template ;

printf '''[Mechanism]
CK_MECHANISM_TYPE = CKM_GENERIC_SECRET_KEY_GEN

[Key]
CKA_CLASS = CKO_SECRET_KEY
CKA_KEY_TYPE = CKK_GENERIC_SECRET
CKA_VALUE_LEN = 32
CKA_LABEL = "hsm:v1:vault-hmac"
CKA_ID = 0x41848
CKA_PRIVATE = CK_TRUE
CKA_TOKEN = CK_TRUE
CKA_SENSITIVE = CK_TRUE
CKA_SIGN = CK_TRUE
CKA_VERIFY = CK_TRUE
CKA_EXTRACTABLE = CK_FALSE
''' > hmac.key_template ;

source /opt/utimaco/etc/bashrc ;

sMSG='' ; # // place-holder for errors
p11tool2 Slot=3 Login=ADMIN,/opt/utimaco/etc/key/ADMIN_CP5.key InitToken=1234 1>&2>/dev/null;
if ! (($? == 0)) ; then sMSG+='ERROR: issue creating Slot 3\n' ; fi ;
p11tool2 Slot=3 LoginSO=1234 InitPin=1234 1>&2>/dev/null ;
if ! (($? == 0)) ; then sMSG+='ERROR: issue initialising Slot 3\n' ; fi ;
p11tool2 Slot=3 LoginUser=1234 GenerateKey=aes.key_template 1>&2>/dev/null;
p11tool2 Slot=3 LoginUser=1234 GenerateKey=hmac.key_template 1>&2>/dev/null;
if ! (($? == 0)) ; then sMSG+='ERROR: labelling Slot 3' ; fi ;
if (( ${#sMSG} == 0 )) ; then pOUT 'SUCCESS: created Slot 3 & initialised it.' ; fi ;
if ! (( ${#sMSG} == 0 )) ; then pERR ${sMSG} ; fi ;

pOUT 'READING CREATED Slot: 3 ...' ;
p11tool2 Slot=3 LoginUser=1234 ListObjects ;

#pOUT 'CREATING Keys: MBK1part1.key,MBK1part2.key ...' ;
#csadm LogonSign=ADMIN,/opt/utimaco/etc/key/ADMIN_CP5.key Key=MBK1part1.key,MBK1part2.key MBKGenerateKey=AES,32,2,2,MBK1 ;

# // other steps...

csadm KeyType=RSA GenKey=vault_s003.key,"vault_s003" ;
if ! (($? == 0)) ; then printf 'GENERATED: vault_s003.key\n' ; fi ;

sMSG='' ;  # // reset error message
cxitool LogonPass=USR_0003,1234 Spec=1 Group=SLOT_0003 KeyFile=vault_s003.key InitializeKey=PKCS-V1_5,false ;
if ! (($? == 0)) ; then sMSG+='ERROR: InitializeKey on Group=SLOT_0003 - Spec=1' ; fi ;
cxitool LogonPass=USR_0003,1234 Spec=2 Group=SLOT_0003 KeyFile=vault_s003.key InitializeKey=PKCS-V1_5,false ;
if ! (($? == 0)) ; then sMSG+='ERROR: InitializeKey on Group=SLOT_0003 - Spec=2' ; fi ;
if (( ${#sMSG} == 0 )) ; then pOUT 'SUCCESS: with InitializeKey on Group=SLOT_0003 - Spec=1 & Spec=2.' ; fi ;
if ! (( ${#sMSG} == 0 )) ; then pERR ${sMSG} ; fi ;

cxitool LogonPass=USR_0003,1234 Spec=1 Group=SLOT_0003 KeyFile=vault_s003.key AuthorizeKey=-1 ;
if ! (($? == 0)) ; then sMSG+='ERROR: AutorizeKey on Group=SLOT_0003 - Spec=1' ; fi ;
cxitool LogonPass=USR_0003,1234 Spec=2 Group=SLOT_0003 KeyFile=vault_s003.key AuthorizeKey=-1 ;
if ! (($? == 0)) ; then sMSG+='ERROR: AuthorizeKey on Group=SLOT_0003 - Spec=2' ; fi ;
if (( ${#sMSG} == 0 )) ; then pOUT 'SUCCESS: with AuthorizeKey on Group=SLOT_0003 - Spec=1 & Spec=2.' ; fi ;
if ! (( ${#sMSG} == 0 )) ; then pERR ${sMSG} ; fi ;

pOUT 'READING KeyInfo of Group=SLOT_0003 Spec=1 & Spec-2 ...' ;
cxitool LogonPass=USR_0003,1234 Spec=1 Group=SLOT_0003 KeyInfo ;
cxitool LogonPass=USR_0003,1234 Spec=2 Group=SLOT_0003 KeyInfo ;
