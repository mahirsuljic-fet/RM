# Računarske mreže (RM)

### [Skripta za instalaciju Cloonix-a izvan Docker okruženja](./cloonix_install.sh)
Za pokretanje skripte potrebno je izvršiti komandu `. ./cloonix_install.sh` u direktoriji u kojoj se nalazi skripta.
Skripta skine sve potrebne resurse, zatim ih odpakuje, instalira Cloonix, doda virtuelne mašine i apparmor profil.
Nakon što skripta uspješno završi ispisati će pokruku `Done`, nakon čega se ***izvan*** Docker okruženja (u *"običnom"* terminalu) pokrenuti Cloonix.
Cloonix se pokreće pomoću `cloonix_net nemo` i zatim `cloonix_gui nemo` (koristeći nemo).
Ako se pojavi poruka `Port: 45211 is in use` potrebno je izvršiti komandu `pkill cloonix-main-se`, nakon čega bi se Cloonix trebao moći pokrenuti pomoću prethodnih komandi.

***Napomena*** \
Na prvim vježbama smo koristili `stretch` virtuelnu mašinu.
Ova skripta instalira i nju, ali ona **ne radi**.
Zašto smo baš koristili `stretch`? 
Ne znam, ali default virtuelna mašina `bookworm` radi za sve što smo do sada radili, tako da u postavku u `kvm_conf` nije potrebno mijenjati.

### Problem sa Cloonix-om - ne otvora se GUI
Prije pokretanja Docker okruženja (`sudo start_container`) potrebno je izvršiti komandu `xhost +`.
