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
#----------------------------------------------------------------------

#######################################################################
cloonix_cli nemo add kvm two 200 2 1 0 ${VM_NAME}.qcow2 & 
#----------------------------------------------------------------------

#######################################################################
cloonix_cli nemo add kvm three 200 2 1 0 ${VM_NAME}.qcow2 & 
#----------------------------------------------------------------------

#######################################################################
cloonix_cli nemo add kvm router1 200 2 2 0 ${VM_NAME}.qcow2 & 
#----------------------------------------------------------------------

#######################################################################
cloonix_cli nemo add kvm router2 200 2 2 0 ${VM_NAME}.qcow2 & 
#----------------------------------------------------------------------


sleep 10
#######################################################################
cloonix_cli nemo add snf sniffer1
cloonix_cli nemo add snf sniffer2 
#----------------------------------------------------------------------

#######################################################################
cloonix_cli nemo add lan one 0 lan1
cloonix_cli nemo add lan sniffer1 0 lan1
cloonix_cli nemo add lan two 0 lan1
cloonix_cli nemo add lan router1 0 lan1
#----------------------------------------------------------------------

#######################################################################
cloonix_cli nemo add lan router1 1 lan2
cloonix_cli nemo add lan router2 0 lan2
#----------------------------------------------------------------------

#######################################################################
cloonix_cli nemo add lan three 0 lan3
cloonix_cli nemo add lan sniffer2 0 lan3
cloonix_cli nemo add lan router2 1 lan3
#----------------------------------------------------------------------


#######################################################################
set +e
for i in one two three router1 router2; do
  while ! cloonix_ssh nemo ${i} "echo" 2>/dev/null; do
    echo ${i} not ready, waiting 5 sec
    sleep 5
  done
done
set -e
#----------------------------------------------------------------------

#######################################################################
cloonix_ssh nemo one "ip addr add dev eth0 10.0.1.2/24"
cloonix_ssh nemo two "ip addr add dev eth0 10.0.1.3/24"
cloonix_ssh nemo router1 "ip addr add dev eth0 10.0.1.1/24"

cloonix_ssh nemo router1 "ip addr add dev eth1 10.1.0.1/30"
cloonix_ssh nemo router2 "ip addr add dev eth0 10.1.0.2/30"

cloonix_ssh nemo router2 "ip addr add dev eth1 192.168.0.1/24"
cloonix_ssh nemo three "ip addr add dev eth0 192.168.0.2/24"


for i in one two three router1 router2; do
  cloonix_ssh nemo ${i} "sysctl -w net.ipv6.conf.all.disable_ipv6=1"
  cloonix_ssh nemo ${i} "sysctl -w net.ipv6.conf.default.disable_ipv6=1"
  cloonix_ssh nemo ${i} "ip link set dev eth0 up"
  cloonix_ssh nemo ${i} "hostnamectl set-hostname ${i}"
  cloonix_ssh nemo ${i} "service systemd-timesyncd stop"
  cloonix_ssh nemo ${i} "rm /var/lib/dhcp/*"
done

cloonix_ssh nemo router1 "ip link set dev eth1 up"
cloonix_ssh nemo router2 "ip link set dev eth1 up"
sleep 1
cloonix_ssh nemo router1 "ip link set mtu 1000 dev eth0"

#----------------------------------------------------------------------
cloonix_ssh nemo three "ip route add default via 192.168.0.1"
cloonix_ssh nemo one "ip route add default via 10.0.1.1"

cloonix_ssh nemo router1 "sysctl net.ipv4.ip_forward=1"
cloonix_ssh nemo router2 "sysctl net.ipv4.ip_forward=1"

cloonix_ssh nemo router1 "ip route add 192.168.0.0/24 via 10.1.0.2"
cloonix_ssh nemo router2 "ip route add 10.0.0.0/16 via 10.1.0.1"


IP_TABLES=$(cat <<-END
iptables -A FORWARD -p tcp -m tcp –tcp-flags SYN,RST SYN -j TCPMSS –clamp-mss-to-pmtu
END
)

cloonix_ssh nemo router1 "echo \"$IP_TABLES\" > /etc/fw.sh"

sleep 3
