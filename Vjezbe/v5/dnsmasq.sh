#!/bin/bash

VM_NAME=stretch

#######################################################################
cloonix_net nemo
#----------------------------------------------------------------------

#######################################################################
cloonix_gui nemo
#----------------------------------------------------------------------


#######################################################################
cloonix_cli nemo add kvm one 200 2 1 0 ${VM_NAME}.qcow2 & 
cloonix_cli nemo add kvm two 200 2 1 0 ${VM_NAME}.qcow2 & 
cloonix_cli nemo add kvm three 200 2 1 0 ${VM_NAME}.qcow2 & 
cloonix_cli nemo add kvm four 200 2 1 0 ${VM_NAME}.qcow2 & 
#----------------------------------------------------------------------
cloonix_cli nemo add kvm router 200 2 4 0 ${VM_NAME}.qcow2 & 
#----------------------------------------------------------------------
for i in {1..4}; do
  cloonix_cli nemo add snf sniffer${i}
done
#----------------------------------------------------------------------
cloonix_cli nemo add nat NAT
#----------------------------------------------------------------------

#######################################################################
cloonix_cli nemo add lan one 0 lan1
cloonix_cli nemo add lan two 0 lan1
cloonix_cli nemo add lan router 0 lan1
cloonix_cli nemo add lan sniffer1 0 lan1
#----------------------------------------------------------------------
cloonix_cli nemo add lan three 0 lan2
cloonix_cli nemo add lan router 1 lan2
cloonix_cli nemo add lan sniffer2 0 lan2
#----------------------------------------------------------------------
cloonix_cli nemo add lan four 0 lan3
cloonix_cli nemo add lan router 2 lan3
cloonix_cli nemo add lan sniffer3 0 lan3
#----------------------------------------------------------------------
cloonix_cli nemo add lan router 3 lan4 
cloonix_cli nemo add lan NAT 0 lan4 
cloonix_cli nemo add lan sniffer4 0 lan4
#----------------------------------------------------------------------

sleep 10

#######################################################################
set +e
for i in one two three four router; do
  while ! cloonix_ssh nemo ${i} "echo" 2>/dev/null; do
    echo ${i} not ready, waiting 5 sec
    sleep 5
  done
done
set -e
#----------------------------------------------------------------------

#######################################################################
for i in one two three four router; do
  cloonix_ssh nemo ${i} "sysctl -w net.ipv6.conf.all.disable_ipv6=1"
  cloonix_ssh nemo ${i} "sysctl -w net.ipv6.conf.default.disable_ipv6=1"
  cloonix_ssh nemo ${i} "hostnamectl set-hostname ${i}"
  cloonix_ssh nemo ${i} "sysctl net.ipv4.tcp_timestamps=0"
  cloonix_ssh nemo ${i} "systemctl stop systemd-timesyncd"
done
cloonix_ssh nemo router "sysctl -w net.ipv4.ip_forward=1"
#----------------------------------------------------------------------

#######################################################################
for i in one two three four router; do
  cloonix_ssh nemo ${i} "ip link set dev eth0 up"
done
cloonix_ssh nemo router "ip link set dev eth1 up"
cloonix_ssh nemo router "ip link set dev eth2 up"
cloonix_ssh nemo router "ip link set dev eth3 up"
cloonix_ssh nemo router "dhclient eth3"
#----------------------------------------------------------------------

#######################################################################
cloonix_ssh nemo router "ip addr add dev eth0 10.0.1.1/24"
cloonix_ssh nemo router "ip addr add dev eth1 10.0.2.1/24"
cloonix_ssh nemo router "ip addr add dev eth2 192.168.0.1/16"
#----------------------------------------------------------------------
cloonix_ssh nemo four "ip addr add dev eth0 192.168.0.2/16"
cloonix_ssh nemo four "ip r add default via 192.168.0.1"

sleep 5

cloonix_ssh nemo router "echo \"listen-address=127.0.0.1,10.0.1.1,10.0.2.1
dhcp-range=eth0,10.0.1.50,10.0.1.150,12h
dhcp-range=eth1,10.0.2.50,10.0.2.150,12h
domain=foo.lan\" > /etc/dnsmasq.conf"

sleep 3

cloonix_ssh nemo router "service dnsmasq restart"

sleep 3

#----------------------------------------------------------------------

#dhcp-host=three,10.0.2.22,infinite
