#!/bin/bash

KVM_MEM=300
KVM_CPU=2
KVM_ETH=1
KVM_WLAN=0

VM_NAME=stretch
VM_FILE=$VM_NAME.qcow2

KVMS=(
  "Cloon1" 
  "Cloon2"
)

IPS=(
  "10.1.20.1" 
  "10.1.20.2"
)

SUBNETS=(
  "24" 
  "24"
)

INTERFACES=(
  "eth0" 
  "eth0"
)

SNIFFER="snf1"

LAN="lan01"

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

cloonix_cli nemo add snf $SNIFFER

sleep 5
#----------------------------------------------------------------------

#######################################################################
set +e
for kvm in ${KVMS[@]}; do
  while ! cloonix_ssh nemo ${kvm} "echo" 2>/dev/null; do
    echo ${i} not ready, waiting 5 sec
    sleep 5
  done

  cloonix_cli nemo add lan ${kvm} 0 $LAN
done
set -e
#----------------------------------------------------------------------

#######################################################################
cloonix_cli nemo add lan $SNIFFER 0 $LAN
cloonix_cli nemo cnf snf on $SNIFFER

for i in ${!KVMS[@]}; do
  cloonix_ssh nemo ${KVMS[i]} "ip address add ${IPS[i]}/${SUBNETS[i]} dev ${INTERFACES[i]}" 2>/dev/null
  cloonix_ssh nemo ${KVMS[i]} "ip link set dev ${INTERFACES[i]} up" 2>/dev/null
done
#----------------------------------------------------------------------

#######################################################################
sniffers=$(find /opt1/cloonix_data -name "*.pcap")
for s in $sniffers; do
  wireshark-gtk -k -i <(tail -f -c +0 "$s") 2>/dev/null &
done
#----------------------------------------------------------------------

green='\033[1;92m'
white='\033[0m'

echo -e "${green}Done${white}"
