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
cloonix_cli nemo add kvm router1 200 2 2 0 ${VM_NAME}.qcow2 & 
cloonix_cli nemo add kvm router2 200 2 2 0 ${VM_NAME}.qcow2 & 
cloonix_cli nemo add kvm router3 200 2 2 0 ${VM_NAME}.qcow2 & 
#----------------------------------------------------------------------

#######################################################################
cloonix_cli nemo add snf sniffer1
cloonix_cli nemo add snf sniffer2 
cloonix_cli nemo add snf sniffer3 
cloonix_cli nemo add snf snifferR 
#----------------------------------------------------------------------

#######################################################################
cloonix_cli nemo add lan one 0 lan1
cloonix_cli nemo add lan router1 0 lan1
cloonix_cli nemo add lan sniffer1 0 lan1
#----------------------------------------------------------------------

#######################################################################
cloonix_cli nemo add lan two 0 lan2
cloonix_cli nemo add lan router2 0 lan2
cloonix_cli nemo add lan sniffer2 0 lan2
#----------------------------------------------------------------------

#######################################################################
cloonix_cli nemo add lan three 0 lan3
cloonix_cli nemo add lan router3 0 lan3
cloonix_cli nemo add lan sniffer3 0 lan3
#----------------------------------------------------------------------

#######################################################################
cloonix_cli nemo add lan router1 1 lanR
cloonix_cli nemo add lan router2 1 lanR
cloonix_cli nemo add lan router3 1 lanR
cloonix_cli nemo add lan snifferR 0 lanR
#----------------------------------------------------------------------

sleep 10

#######################################################################
set +e
for i in one two three router1 router2 router3; do
  while ! cloonix_ssh nemo ${i} "echo" 2>/dev/null; do
    echo ${i} not ready, waiting 5 sec
    sleep 5
  done
done
set -e
#----------------------------------------------------------------------

#######################################################################
cloonix_ssh nemo router1 "ip addr add dev eth0 192.168.1.1/24"
cloonix_ssh nemo router1 "ip addr add dev eth1 192.168.0.1/24"
cloonix_ssh nemo router2 "ip addr add dev eth0 192.168.2.1/24"
cloonix_ssh nemo router2 "ip addr add dev eth1 192.168.0.2/24"
cloonix_ssh nemo router3 "ip addr add dev eth0 192.168.3.1/24"
cloonix_ssh nemo router3 "ip addr add dev eth1 192.168.0.3/24"
#----------------------------------------------------------------------

#######################################################################
cloonix_ssh nemo one "ip addr add dev eth0 192.168.1.101/24"
cloonix_ssh nemo two "ip addr add dev eth0 192.168.2.102/24"
cloonix_ssh nemo three "ip addr add dev eth0 192.168.3.103/24"
#----------------------------------------------------------------------

#######################################################################
for i in one two three router1 router2 router3; do
  cloonix_ssh nemo ${i} "sysctl -w net.ipv6.conf.all.disable_ipv6=1"
  cloonix_ssh nemo ${i} "sysctl -w net.ipv6.conf.default.disable_ipv6=1"
  cloonix_ssh nemo ${i} "hostnamectl set-hostname ${i}"
  cloonix_ssh nemo ${i} "sysctl net.ipv4.tcp_timestamps=0"
  cloonix_ssh nemo ${i} "systemctl stop systemd-timesyncd"
done
#----------------------------------------------------------------------

#######################################################################
for i in one two three router1 router2 router3; do
  cloonix_ssh nemo ${i} "ip link set dev eth0 up"
done

for r in router1 router2 router3; do
  cloonix_ssh nemo ${r} "ip link set dev eth1 up"
done
#----------------------------------------------------------------------

#######################################################################
cloonix_cli nemo cnf snf on sniffer1
cloonix_cli nemo cnf snf on sniffer2
cloonix_cli nemo cnf snf on sniffer3
cloonix_cli nemo cnf snf on snifferR

sleep 1

sniffers=$(find /opt1/cloonix_data -name "*.pcap")
for s in $sniffers; do
  wireshark-gtk -k -i <(tail -f -c +0 "$s") &
done
#----------------------------------------------------------------------
