#!/usr/bin/env bash

VM_NAME=stretch
NAME=nemo

KVM_MEM=200
KVM_CPU=2
KVM_ETH=1
KVM_WLAN=0

ROUTER_ETH=4

#######################################################################
echo "checking for running cloonix..."
set +e
[ -z $(cloonix_cli $NAME kil | grep "TIMEOUT") ] && echo "closed running cloonix" && echo "waiting 5 seconds..." && sleep 5
set -e
cloonix_net $NAME
cloonix_gui $NAME
#######################################################################

#######################################################################
cloonix_cli $NAME add kvm one $KVM_MEM $KVM_CPU $KVM_ETH $KVM_WLAN ${VM_NAME}.qcow2 & 
cloonix_cli $NAME add kvm two $KVM_MEM $KVM_CPU $KVM_ETH $KVM_WLAN ${VM_NAME}.qcow2 & 
cloonix_cli $NAME add kvm three $KVM_MEM $KVM_CPU $KVM_ETH $KVM_WLAN ${VM_NAME}.qcow2 & 
cloonix_cli $NAME add kvm four $KVM_MEM $KVM_CPU $KVM_ETH $KVM_WLAN ${VM_NAME}.qcow2 & 
#----------------------------------------------------------------------
cloonix_cli $NAME add kvm router $KVM_MEM $KVM_CPU $ROUTER_ETH $KVM_WLAN ${VM_NAME}.qcow2 & 
#----------------------------------------------------------------------
for i in {1..4}; do
  cloonix_cli $NAME add snf sniffer${i}
done
#----------------------------------------------------------------------
cloonix_cli nemo add nat NAT
#----------------------------------------------------------------------

#######################################################################
cloonix_cli $NAME add lan one 0 lan1
cloonix_cli $NAME add lan two 0 lan1
cloonix_cli $NAME add lan router 0 lan1
cloonix_cli $NAME add lan sniffer1 0 lan1
#----------------------------------------------------------------------
cloonix_cli $NAME add lan three 0 lan2
cloonix_cli $NAME add lan router 1 lan2
cloonix_cli $NAME add lan sniffer2 0 lan2
#----------------------------------------------------------------------
cloonix_cli $NAME add lan four 0 lan3
cloonix_cli $NAME add lan router 2 lan3
cloonix_cli $NAME add lan sniffer3 0 lan3
#----------------------------------------------------------------------
cloonix_cli $NAME add lan router 3 lan4 
cloonix_cli nemo add lan NAT 0 lan4 
cloonix_cli $NAME add lan sniffer4 0 lan4
#----------------------------------------------------------------------

sleep 5

#######################################################################
set +e
for i in one two three four router; do
  while ! cloonix_ssh $NAME ${i} "echo" 2>/dev/null; do
    echo ${i} not ready, waiting 5 sec
    sleep 5
  done
done
set -e
#----------------------------------------------------------------------

#######################################################################
for name in one two three four router; do
  cloonix_ssh $NAME ${name} "sysctl -w net.ipv6.conf.all.disable_ipv6=1" 2>/dev/null
  cloonix_ssh $NAME ${name} "sysctl -w net.ipv6.conf.default.disable_ipv6=1" 2>/dev/null
  cloonix_ssh $NAME ${name} "hostnamectl set-hostname ${name}" 2>/dev/null
  cloonix_ssh $NAME ${name} "sysctl net.ipv4.tcp_timestamps=0" 2>/dev/null
  cloonix_ssh $NAME ${name} "systemctl stop systemd-timesyncd" 2>/dev/null
done
cloonix_ssh $NAME router "sysctl -w net.ipv4.ip_forward=1" 2>/dev/null
#----------------------------------------------------------------------

#######################################################################
for name in one two three four router; do
  cloonix_ssh $NAME ${name} "ip link set dev eth0 up" 2>/dev/null
done
for i in {1..3}; do
  cloonix_ssh $NAME router "ip link set dev eth${i} up" 2>/dev/null
done
cloonix_ssh $NAME router "dhclient eth3" 2>/dev/null
#----------------------------------------------------------------------

#######################################################################
cloonix_ssh $NAME router "ip addr add dev eth0 10.0.1.1/24" 2>/dev/null
cloonix_ssh $NAME router "ip addr add dev eth1 10.0.2.1/24" 2>/dev/null
cloonix_ssh $NAME router "ip addr add dev eth2 192.168.0.1/16" 2>/dev/null
#----------------------------------------------------------------------
cloonix_ssh $NAME four "ip addr add dev eth0 192.168.0.2/16" 2>/dev/null
cloonix_ssh $NAME four "ip r add default via 192.168.0.1" 2>/dev/null
#----------------------------------------------------------------------
cloonix_ssh $NAME router "echo \"listen-address=127.0.0.1,10.0.1.1,10.0.2.1
dhcp-range=eth0,10.0.1.50,10.0.1.150,12h
dhcp-range=eth1,10.0.2.50,10.0.2.150,12h
dhcp-host=three,10.0.2.22,infinite
domain=foo.lan\" > /etc/dnsmasq.conf" 2>/dev/null

sleep 1

cloonix_ssh $NAME router "service dnsmasq restart" 2>/dev/null

sleep 1

#----------------------------------------------------------------------
echo "Adding IPs using DHCP..."
cloonix_ssh $NAME one "dhclient eth0" 2>/dev/null
cloonix_ssh $NAME two "dhclient eth0" 2>/dev/null
cloonix_ssh $NAME three "dhclient eth0" 2>/dev/null
#----------------------------------------------------------------------

green='\033[1;92m'
reset='\033[0m'

echo -e "${green}Done${reset}"
