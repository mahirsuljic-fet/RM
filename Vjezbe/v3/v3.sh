#!/usr/bin/env bash

KVM_MEM=300
KVM_CPU=2
KVM_ETH=1
KVM_WLAN=0

ROUTER_MEM=$KVM_MEM
ROUTER_CPU=$KVM_CPU
ROUTER_ETH=2
ROUTER_WLAN=$KVM_WLAN

VM_NAME=stretch
VM_FILE=$VM_NAME.qcow2

KVMS=(
  "one" 
  "two"
  "three"
)

KVM_IPS=(
  "10.0.0.2" 
  "10.0.0.3"
  "192.168.0.2"
)

KVM_SUBNETS=(
  "8" 
  "8" 
  "16"
)

KVM_INTERFACES=(
  "eth0" 
  "eth0"
  "eth0"
)

ROUTER_NAME="router"

ROUTER_IPS=(
  "10.0.0.1"
  "192.168.0.1"
)

ROUTER_INTERFACES=(
  "eth0" 
  "eth1"
)

ROUTER_SUBNETS=(
  "8" 
  "16"
)

LANS=(
  "lan1"
  "lan2"
)

SNIFFERS=(
  "sniffer1"
  "sniffer2"
)

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
for kvm in ${KVMS[@]}; do
  cloonix_cli nemo add kvm $kvm $KVM_MEM $KVM_CPU $KVM_ETH $KVM_WLAN $VM_FILE &
done
#----------------------------------------------------------------------

#######################################################################
cloonix_cli nemo add kvm $ROUTER_NAME $ROUTER_MEM $ROUTER_CPU $ROUTER_ETH $ROUTER_WLAN $VM_FILE &
#----------------------------------------------------------------------

#######################################################################
for snf in ${SNIFFERS[@]}; do
  cloonix_cli nemo add snf $snf
done
#----------------------------------------------------------------------

sleep 5

#######################################################################
set +e
for i in ${KVMS[@]} $ROUTER_NAME; do
  while ! cloonix_ssh nemo ${i} "echo" 2>/dev/null; do
    echo ${i} not ready, waiting 5 sec
    sleep 5
  done
done
set -e
#----------------------------------------------------------------------

#######################################################################
cloonix_cli nemo add lan ${KVMS[0]} 0 ${LANS[0]}
cloonix_cli nemo add lan ${KVMS[1]} 0 ${LANS[0]}
cloonix_cli nemo add lan ${ROUTER_NAME} 0 ${LANS[0]}
cloonix_cli nemo add lan ${SNIFFERS[0]} 0 ${LANS[0]}
#----------------------------------------------------------------------

#######################################################################
cloonix_cli nemo add lan ${KVMS[2]} 0 ${LANS[1]}
cloonix_cli nemo add lan ${ROUTER_NAME} 1 ${LANS[1]}
cloonix_cli nemo add lan ${SNIFFERS[1]} 0 lan2
#----------------------------------------------------------------------

#######################################################################
for i in ${!ROUTER_IPS[@]}; do
  cloonix_ssh nemo router "ip addr add ${ROUTER_IPS[i]}/${ROUTER_SUBNETS[i]} dev ${ROUTER_INTERFACES[i]}" 2>/dev/null
done
#----------------------------------------------------------------------

#######################################################################
for i in ${!KVMS[@]}; do
  cloonix_ssh nemo ${KVMS[i]} "ip addr add ${KVM_IPS[i]}/${KVM_SUBNETS[i]} dev ${KVM_INTERFACES[i]}" 2>/dev/null
done
#----------------------------------------------------------------------

#######################################################################
for kvm in ${KVMS[@]} $ROUTER_NAME; do
  cloonix_ssh nemo ${kvm} "sysctl -w net.ipv6.conf.all.disable_ipv6=1" 2>/dev/null
  cloonix_ssh nemo ${kvm} "sysctl -w net.ipv6.conf.default.disable_ipv6=1" 2>/dev/null
  cloonix_ssh nemo ${kvm} "hostnamectl set-hostname ${kvm}" 2>/dev/null
  cloonix_ssh nemo ${kvm} "sysctl net.ipv4.tcp_timestamps=0" 2>/dev/null
  cloonix_ssh nemo ${kvm} "systemctl stop systemd-timesyncd" 2>/dev/null
done

cloonix_ssh nemo ${ROUTER_NAME} "sysctl net.ipv4.ip_forward=1 -w" 2>/dev/null
#----------------------------------------------------------------------

#######################################################################
for kvm in ${KVMS[@]}; do
  cloonix_ssh nemo ${kvm} "ip link set dev eth0 up" 2>/dev/null
done

for interface in ${ROUTER_INTERFACES[@]}; do
  cloonix_ssh nemo $ROUTER_NAME "ip link set dev ${interface} up" 2>/dev/null
done

for snf in ${SNIFFERS[@]}; do
  cloonix_cli nemo cnf snf on ${snf}
done

cloonix_ssh nemo ${KVMS[0]} "ip route add default via ${ROUTER_IPS[0]}" 2>/dev/null
cloonix_ssh nemo ${KVMS[1]} "ip route add default via ${ROUTER_IPS[0]}" 2>/dev/null
cloonix_ssh nemo ${KVMS[2]} "ip route add default via ${ROUTER_IPS[1]}" 2>/dev/null

snf_files=$(find /opt1/cloonix_data -name "*.pcap")
for file in $snf_files; do
  wireshark-gtk -k -i <(tail -f -c +0 "$file") 2> /dev/null &
done
#----------------------------------------------------------------------

green='\033[1;92m'
reset='\033[0m'

echo -e "${green}Done${reset}"
