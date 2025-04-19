#!/bin/bash

NAME=nemo
VM_NAME=stretch

#######################################################################
cloonix_net $NAME
cloonix_gui $NAME
sleep 2
#######################################################################

setup_lan() {
  lan_name=$1
  for kvm in ${!lan_elements[@]};
  do
    cloonix_cli $NAME add lan $kvm ${lan_elements[$kvm]} $lan_name
    sleep 2
  done
  sleep 3
}

create_host() {
  name=$1
  cloonix_cli $NAME add kvm $name 200 2 1 0 ${VM_NAME}.qcow2 & 
}

setup_host() {
  name=$1
  ip_addr=$2
  default_gateway=$3
  cloonix_ssh $NAME $name "ip addr add dev eth0 $ip_addr"
  cloonix_ssh $NAME $name "ip link set dev eth0 up"
  sleep 2
  cloonix_ssh $NAME $name "ip route add default via $default_gateway"
}

set_interface() {
  name=$1
  ip=$2
  num=$3
  cloonix_ssh $NAME $name "ip addr add dev eth$num $ip"
  sleep 2
  cloonix_ssh $NAME $name "ip link set dev eth$num up"
  sleep 2
}

create_router() {
  name=$1
  num=$2
  cloonix_cli $NAME add kvm $name 200 2 $num 0 ${VM_NAME}.qcow2 & 
}

enable_routing() {
  name=$1
  cloonix_ssh $NAME $name "sysctl -w net.ipv4.ip_forward=1"
  sleep 2
}

setup_router_2() {
  name=$1
  ip_addr0=$2
  ip_addr1=$3
  set_interface $name $ip_addr0 0
  set_interface $name $ip_addr1 1
  enable_routing $name
}

setup_router_3() {
  name=$1
  ip_addr0=$2
  ip_addr1=$3
  ip_addr2=$4
  set_interface $name $ip_addr0 0
  set_interface $name $ip_addr1 1
  set_interface $name $ip_addr2 2
  enable_routing $name
}

#######################################################################
create_router main_router 3
create_router router1 2
create_router router2 2
create_router router3 2
create_host one
create_host two 
create_host three
sleep 10
#######################################################################

setup_router_3 "main_router" "20.10.0.2/8" "30.10.0.2/8" "40.0.0.2/8"
#######################################################################

#######################################################################
setup_router_2 "router1" "10.0.0.2/8" "20.10.0.1/8"
setup_host "one" "10.0.0.1/8" "10.0.0.2"
cloonix_ssh $NAME router1 "ip route add default via 20.10.0.2"
#######################################################################

#######################################################################
setup_router_2 "router2" "121.10.0.2/8" "30.10.0.1/8"
setup_host "two" "121.10.0.1/8" "121.10.0.2"
cloonix_ssh $NAME router2 "ip route add default via 30.10.0.2"
#######################################################################

#######################################################################
setup_router_2 "router3" "120.0.0.2/8" "40.0.0.1/8"
setup_host "three" "120.0.0.1/8" "120.0.0.2"
cloonix_ssh $NAME router3 "ip route add default via 40.0.0.2"
#######################################################################

#######################################################################
cloonix_cli $NAME add snf sniffer1
declare -A lan_elements=(["one"]=0 ["router1"]=0 ["sniffer1"]=0)
setup_lan lan1
#######################################################################

#######################################################################
cloonix_cli $NAME add snf sniffer2
lan_elements=(["two"]=0 ["router2"]=0 ["sniffer2"]=0)
setup_lan lan2
#######################################################################

#######################################################################
cloonix_cli $NAME add snf sniffer3
lan_elements=(["three"]=0 ["router3"]=0 ["sniffer3"]=0)
setup_lan lan3
#######################################################################

#######################################################################
cloonix_cli $NAME add snf sniffer4
lan_elements=(["router1"]=1 ["main_router"]=0 ["sniffer4"]=0)
setup_lan lan4
#######################################################################

#######################################################################
cloonix_cli $NAME add snf sniffer5
lan_elements=(["router2"]=1 ["main_router"]=1 ["sniffer5"]=0)
setup_lan lan5
#######################################################################

#######################################################################
cloonix_cli $NAME add snf sniffer6
lan_elements=(["router3"]=1 ["main_router"]=2 ["sniffer6"]=0)
setup_lan lan6
#######################################################################

#######################################################################
cloonix_ssh $NAME main_router "ip route add 10.0.0.0/8 via 20.10.0.1 dev eth0"
cloonix_ssh $NAME main_router "ip route add 121.0.0.0/8 via 30.10.0.1 dev eth1"
cloonix_ssh $NAME main_router "ip route add 120.0.0.0/8 via 40.0.0.1 dev eth2"
sleep 2
