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
cloonix_cli nemo add kvm four 200 2 1 0 ${VM_NAME}.qcow2 & 
#----------------------------------------------------------------------

#######################################################################
cloonix_cli nemo add kvm five 200 2 1 0 ${VM_NAME}.qcow2 & 
#----------------------------------------------------------------------


#######################################################################
cloonix_cli nemo add kvm router1 200 2 3 0 ${VM_NAME}.qcow2 & 
#----------------------------------------------------------------------

#######################################################################
cloonix_cli nemo add kvm router2 200 2 2 0 ${VM_NAME}.qcow2 & 
#----------------------------------------------------------------------


sleep 10
#######################################################################
cloonix_cli nemo add snf sniffer1
cloonix_cli nemo add snf sniffer2 
cloonix_cli nemo add snf sniffer3 
#----------------------------------------------------------------------

#######################################################################
cloonix_cli nemo add lan one 0 lan1
cloonix_cli nemo add lan sniffer1 0 lan1
cloonix_cli nemo add lan two 0 lan1
cloonix_cli nemo add lan router1 0 lan1
#----------------------------------------------------------------------

#######################################################################
cloonix_cli nemo add lan three 0 lan2
cloonix_cli nemo add lan sniffer2 0 lan2
cloonix_cli nemo add lan four 0 lan2
cloonix_cli nemo add lan router1 1 lan2
#----------------------------------------------------------------------

#######################################################################
cloonix_cli nemo add lan router1 2 lan3
cloonix_cli nemo add lan router2 0 lan3
#----------------------------------------------------------------------

#######################################################################
cloonix_cli nemo add lan five 0 lan4
cloonix_cli nemo add lan sniffer3 0 lan4
cloonix_cli nemo add lan router2 1 lan4
#----------------------------------------------------------------------



#######################################################################
set +e
for i in one two three four five router1 router2; do
  while ! cloonix_ssh nemo ${i} "echo" 2>/dev/null; do
    echo ${i} not ready, waiting 5 sec
    sleep 5
  done
done
set -e
#----------------------------------------------------------------------

#######################################################################
for i in one two three four five router1 router2; do
  if [[ ${i} != "four" ]]; then
    cloonix_ssh nemo ${i} "hostnamectl set-hostname ${i}"
    cloonix_ssh nemo ${i} "ip link set dev eth0 up"
  fi
  cloonix_ssh nemo ${i} "echo 'send fqdn.fqdn = gethostname();' >> /etc/dhcp/dhclient.conf"
  cloonix_ssh nemo ${i} "service systemd-timesyncd stop"
  cloonix_ssh nemo ${i} "rm /var/lib/dhcp/*"
done

cloonix_ssh nemo router1 "ip link set dev eth1 up"
cloonix_ssh nemo router1 "ip link set dev eth2 up"
cloonix_ssh nemo router2 "ip link set dev eth1 up"

#----------------------------------------------------------------------

cloonix_ssh nemo router1 "sysctl net.ipv4.ip_forward=1"
cloonix_ssh nemo router2 "sysctl net.ipv4.ip_forward=1"
cloonix_ssh nemo router1 "sysctl net.ipv6.conf.all.forwarding=1"
cloonix_ssh nemo router2 "sysctl net.ipv6.conf.all.forwarding=1"


cloonix_ssh nemo router1 "ip -6 a add fd00:dead:beef:1::1/64 dev eth0"
cloonix_ssh nemo router1 "ip -6 a add fd00:dead:beef:2::1/64 dev eth1"
cloonix_ssh nemo router1 "ip -6 a add fd00:dead:beef:3::1/64 dev eth2"
#----------------------------------------------------------------------
# DHCP_CONF=$(cat <<-END
# local=/foo.lan/
# expand-hosts
# domain=foo.lan
# dhcp-range=eth0,10.0.1.50,10.0.1.150,12h
# dhcp-range=eth1,10.0.2.50,10.0.2.150,12h
# listen-address=127.0.0.1,10.0.1.1,10.0.2.1
# dhcp-host=one,10.0.1.5
# cname=pet.foo.lan,five.foo.lan
# END
# )

PY_SERVER=$(cat <<-END
import socket
import thread

def handle(client):
  while True:
    data = client.recv(4096)
    if len(data) == 0:
      break
    print(data)

soc = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
soc.bind(('', 10000))
soc.listen(5)
print('Server up and running')

while True:
  client, _ = soc.accept()
  th = thread.start_new_thread(handle, (client, ))
END
)

# IP_TABLES=$(cat <<-END
# iptables -t nat -A POSTROUTING -o eth2 -j MASQUERADE
# iptables -A FORWARD -i eth2 -o eth1 -m state --state RELATED,ESTABLISHED -j ACCEPT
# iptables -A FORWARD -i eth1 -o eth2 -j ACCEPT
# iptables -A FORWARD -i eth2 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
# iptables -A FORWARD -i eth0 -o eth2 -j ACCEPT
# iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
# iptables -A FORWARD -i eth0 -o eth1 -j ACCEPT
# iptables -P FORWARD DROP
# END
# )


DHCP_CONF=$(cat <<- END
local=/foo.bar/
domain=foo.bar
# dhcp-range=::,ra-only,constructor:eth0
# dhcp-range=::,ra-stateless,constructor:eth0
# dhcp-range=::5,::ffff,slaac,constructor:eth1
END
)

cloonix_ssh nemo router1 "echo \"$DHCP_CONF\" > /etc/dnsmasq.conf"
# cloonix_ssh nemo router1 "echo '192.168.0.2 five' >> /etc/hosts"
# cloonix_ssh nemo router1 "service dnsmasq restart"
# cloonix_ssh nemo router1 "echo \"$IP_TABLES\" > /etc/fw.sh"
# cloonix_ssh nemo five "echo \"nameserver 10.0.1.1\" > /etc/resolv.conf"
cloonix_ssh nemo five "echo \"$PY_SERVER\" > server.py"

