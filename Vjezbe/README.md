Svaka vježba je odvojena u zasebnu direktoriju.
Svaka direktorija sadrži `.md` fajl koji je opis šta i kako se radi u vježbi.

Pored `.md` fajla također imaju i `.sh` fajlovi (skripte) koji kada se izvrše naprave cijelu topologiju unutar Cloonixa,
onakvu kakva treba biti nakon što se pravilno uradi vježba.
Skripte također automatski otvore i Wireshark za svaki sniffer.
Nakon što skripta završi, u terminalu će se zelenim slovima ispisati poruka "**Done**".
Skripte se pokreću pomoću `. ./vX.sh` (`X` je broj vježbe, npr. `. ./v1.sh`) unutar containera.
Skripte se također mogu pokrenuti pomoću `./vX.sh` nakon što im se dadne executable permission sa `chmod +x vX.sh`.

Pored `.md` fajlova i skripti, unutar nekih direktorija se također nalaze fajlovi koje nam je asistentica dala.
Npr. u [`v3`](./v3/) se nalazi skripta [`routing.sh`](./v3/routing.sh) koja napravi osnovnu topologiju potrebnu za vježbu,
kako ne bi morali ručno svaki put sve spajati i konfigurisati.

| Br.                | Opis
| ------------------ | -------------------------------------------------------------------------------------------
|  [1](./v1/v1.md)   | Upoznavanje sa Cloonix-om i `ip` utility-em (`ip address` i `ip link`)
|  [2](./v2/v2.md)   | ARP, Wireshark, `ping` (ICMP) i ARP cache (`ip neighbour`)
|  [3](./v3/v3.md)   | Routing, `ip route`, otvoranje više Wireshark-a i skripte.
|  [4](./v4/v4.md)   | `traceroute`, `hping3`, MTU (citanje i modifikacija uz pomoc `ip` utility-a), fragmentacija
|  [5](./v5/v5.md)   | DHCP
|  [6](./v6/v6.md)   | DNS
|  [7](./v7/v7.md)   | Stateless firewall (`iptables` i `netcat`)
|  [8](./v8/v8.md)   | Stateful firewall i NAT
|  [9](./v9/v9.md)   | IPv6
| [10](./v10/v10.md) | TCP
