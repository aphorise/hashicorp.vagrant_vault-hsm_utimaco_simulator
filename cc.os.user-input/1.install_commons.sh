#!/bin/bash

# // libraries needed by CP5 simulator
HSM_DEPS='glibc.i686 libgcc.i686 libstdc++.i686' ;

yum -y -q --nogpgcheck update ;
#yum -y -q --nogpgcheck groups mark convert
yum -y -q --nogpgcheck groupinstall "Development Tools" ;
yum -y -q clean all ;
yum -y -q makecache ;
yum -y -q --nogpgcheck install epel-release && yum -y -q --nogpgcheck update ;
yum -y -q --nogpgcheck install ${HSM_DEPS} nano htop net-tools nload unzip wget opensc jq;

# // .bashrc profile alias and history settings.
sBASH_DEFAULT='''
SHELL_SESSION_HISTORY=0
export HISTSIZE=1000000
export HISTFILESIZE=100000000
export HISTCONTROL=ignoreboth:erasedups
PROMPT_COMMAND="history -a;$PROMPT_COMMAND"
alias nano="nano -c"
alias grep="grep --color=auto"
alias ls="ls --color=auto"
alias dir="dir --color=auto"
alias reset="reset; stty sane; tput rs1; clear; echo -e \\"\033c\\""
alias jv="sudo journalctl -u vault.service --no-pager -f --output cat"
alias jreset="sudo journalctl --since now && sudo journalctl --vacuum-time=1s"
PS1="\[\e[01;36m\]\u\[\e[01;37m\]@\[\e[01;33m\]\H\[\e[01;37m\]:\[\e[01;32m\]\w\[\e[01;37m\]\$\[\033[0;37m\] "
''' ;
echo "${sBASH_DEFAULT}" >> ~/.bashrc ;
if [[ $(logname) != $(whoami) ]] ; then echo "${sBASH_DEFAULT}" >> /home/$(logname)/.bashrc ; fi ;
printf 'BASH: defaults in (.bashrc) profile set.\n' ;

find /usr/share/nano/ -iname "*.nanorc" -exec echo include {} \; >> ~/.nanorc
if [[ $(logname) != $(whoami) ]] ; then find /usr/share/nano/ -iname "*.nanorc" -exec echo include {} \; >> /home/$(logname)/.nanorc ; fi ;

printf 'http_caching=packages\n' >> /etc/yum.conf
