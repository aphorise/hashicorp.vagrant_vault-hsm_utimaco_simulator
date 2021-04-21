# HashiCorp `vagrant` demo of `vault` with Utimaco HSM Simulator.

A mock `Vagrantfile` of [Utimaco HSM Simulator (aka Cryptoserver CP5)](https://hsm.utimaco.com/products-hardware-security-modules/hsm-simulators/securityserver-simulator/) intended for integration with [Vault](https://www.vaultproject.io/).

:warning: **IMPORTANT**: You must register to obtain an evaluation of CP5 Simulator. :warning:


## Usage & Workflow

Place the archived simulator file (`CryptoServerCP5-SupportingCD-V5.1.1.1.zip`) in the directory `vm_files/`.

Refer to the contents of **`Vagrantfile`** & directory: `cc.os.user-input` for complete details.


```bash
vagrant up ;
# // ... output of provisioning steps.

vagrant global-status ; # should show running nodes
  # id       name        provider   state   directory
  # -------------------------------------------------------------------------------------
  # 11701be  centos-vault1             virtualbox running  /Users/auser/hashicorp.vagrant_vault-hsm_utimaco_simulator

# // On a separate Terminal session check status of HSM & vault
vagrant ssh ;
  # ...

#vagrant@centos-vault1:~$ \
csadm GetState
csadm ListFirmware
csadm ListUser
p11tool2 ListSlots=Status
cxitool LogonPass=USR_0003,1234 Spec=1 Group=SLOT_0003 KeyInfo
cxitool LogonPass=USR_0003,1234 Spec=2 Group=SLOT_0003 KeyInfo
vault status
# vault ...
```

[![asciicast](https://asciinema.org/a/407558.svg)](https://asciinema.org/a/407558)

------
