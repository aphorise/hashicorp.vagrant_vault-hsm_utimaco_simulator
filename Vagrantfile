# -*- mode: ruby -*-
# vi: set ft=ruby :
VV1='VAULT_VERSION='+'1.7.10+ent.hsm'  # VV1='' to Install Latest OSS
CLUSTERA_VAULT_NAME = 'hsm1'  # // Vault A Cluster Name

sNET='en0: Wi-Fi'  # // network adaptor to use for bridged mode
#sNET='en6: USB 10/100/1000 LAN'  # // network adaptor to use for bridged mode
sVUSER='vagrant'  # // vagrant user
sHOME="/home/#{sVUSER}"  # // home path for vagrant user
sPTH='cc.os.user-input'  # // path where scripts are expected

sCLUSTERA_IP_CLASS_D='192.168.178'  # // Consul A NETWORK CIDR forconfigs.
iCLUSTERA_IP_CONSUL_CLASS_D=110  # // Consul A IP starting D class (increment or de)
iCLUSTERA_IP_VAULT_CLASS_D=253  # // Vault A Leader IP starting D class (increment or de)
sCLUSTERA_IP_CA_NODE="#{sCLUSTERA_IP_CLASS_D}.#{iCLUSTERA_IP_VAULT_CLASS_D-1}"  # // Cluster A - static IP of CA

aCLUSTERA_FILES =  # // Cluster A files to copy to instances
[
	"vm_files/.",    # .zip files like simulator goes here.
	"vault_files/."  # "vault_files/vault_seal.hcl", "vault_files/vault_license.txt"  ## // for individual files
];

Vagrant.configure("2") do |config|
	config.vm.box = "centos/7"
	config.vm.box_check_update = false  # // disabled to reduce verbosity - better enabled
	#config.vm.box_version = "10.4.0"  # // Debian tested version.
	# // OS may be "ubuntu/bionic64" or "ubuntu/focal64" as well.

	config.vm.provider "virtualbox" do |v|
		v.memory = 4096  # // RAM / Memory
		v.cpus = 1  # // CPU Cores / Threads
		v.check_guest_additions = false  # // disable virtualbox guest additions (no default warning message)
	end

	config.vm.define vm_name="centos-vault1" do |vault_node|
		vault_node.vm.hostname = vm_name
		vault_node.vm.network "public_network", bridge: "#{sNET}", ip: "#{sCLUSTERA_IP_CLASS_D}.#{iCLUSTERA_IP_VAULT_CLASS_D}"
		# vault_node.vm.network "forwarded_port", guest: 80, host: "5828#{iX}", id: "#{vm_name}"

		# // copy additional files for setup / software across (eg CP5 Simulator)
		for sFILE in aCLUSTERA_FILES
			if(File.file?("#{sFILE}") || File.directory?("#{sFILE}"))
				vault_node.vm.provision "file", source: "#{sFILE}", destination: "#{sHOME}"
			end
		end

		# // IN ORDER: install commons then setup CP5 simulator
		vault_node.vm.provision "file", source: "#{sPTH}/1.install_commons.sh", destination: "#{sHOME}/install_commons.sh"
		vault_node.vm.provision "shell", inline: "/bin/bash -c '#{sHOME}/install_commons.sh'"
		vault_node.vm.provision "file", source: "#{sPTH}/2.install_hsm_cp5_sim.sh", destination: "#{sHOME}/install_hsm_cp5_sim.sh"
		vault_node.vm.provision "shell", inline: "/bin/bash -c '#{sHOME}/install_hsm_cp5_sim.sh'"
        # // now try setting up Vault
        vault_node.vm.provision "file", source: "#{sPTH}/3.install_vault.sh", destination: "#{sHOME}/install_vault.sh"
        vault_node.vm.provision "shell", inline: "/bin/bash -c '#{VV1} VAULT_CLUSTER_NAME='#{CLUSTERA_VAULT_NAME}' USER='#{sVUSER}' #{sHOME}/install_vault.sh'"
	end
end
