#!/bin/bash

VM_NAME=stretch

#######################################################################
set +e
cloonix_cli nemo kil
set -e
echo waiting 5 sec
echo
sleep 5 
cloonix_net nemo
#----------------------------------------------------------------------

#######################################################################
cloonix_gui nemo
#----------------------------------------------------------------------


#######################################################################
cloonix_cli nemo add kvm one 200 2 1 0 ${VM_NAME}.qcow2 & 
cloonix_cli nemo add kvm two 200 2 1 0 ${VM_NAME}.qcow2 & 
cloonix_cli nemo add kvm three 200 2 1 0 ${VM_NAME}.qcow2 & 
#----------------------------------------------------------------------

#######################################################################
cloonix_cli nemo add kvm router 200 2 2 0 ${VM_NAME}.qcow2 & 
#----------------------------------------------------------------------

#######################################################################
cloonix_cli nemo add snf sniffer1
cloonix_cli nemo add snf sniffer2 
#----------------------------------------------------------------------

#######################################################################
cloonix_cli nemo add lan one 0 lan1
cloonix_cli nemo add lan two 0 lan1
cloonix_cli nemo add lan router 0 lan1
cloonix_cli nemo add lan sniffer1 0 lan1
#----------------------------------------------------------------------

#######################################################################
cloonix_cli nemo add lan three 0 lan2
cloonix_cli nemo add lan router 1 lan2
cloonix_cli nemo add lan sniffer2 0 lan2
#----------------------------------------------------------------------

sleep 10

#######################################################################
set +e
for i in one two three router; do
  while ! cloonix_ssh nemo ${i} "echo" 2>/dev/null; do
    echo ${i} not ready, waiting 5 sec
    sleep 5
  done
done
set -e
#----------------------------------------------------------------------

#######################################################################
cloonix_ssh nemo router "ip addr add dev eth0 10.0.0.1/8"
cloonix_ssh nemo router "ip addr add dev eth1 192.168.0.1/16"
#----------------------------------------------------------------------

#######################################################################
cloonix_ssh nemo three "ip addr add dev eth0 192.168.0.2/16"
#----------------------------------------------------------------------

#######################################################################
for i in one two three router; do
  cloonix_ssh nemo ${i} "sysctl -w net.ipv6.conf.all.disable_ipv6=1"
  cloonix_ssh nemo ${i} "sysctl -w net.ipv6.conf.default.disable_ipv6=1"
  cloonix_ssh nemo ${i} "hostnamectl set-hostname ${i}"
  cloonix_ssh nemo ${i} "sysctl net.ipv4.tcp_timestamps=0"
  cloonix_ssh nemo ${i} "systemctl stop systemd-timesyncd"
done
#----------------------------------------------------------------------

#######################################################################
for i in one three router; do
  cloonix_ssh nemo ${i} "ip link set dev eth0 up"
done
cloonix_ssh nemo router "ip link set dev eth1 up"
#----------------------------------------------------------------------


