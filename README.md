# Računarske mreže (RM)

### [Skripta za instalaciju Cloonix-a](./cloonix_install.sh)
Ovo je skripta koja instalira Cloonix izvan Docker okruženja.
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

*Šta sam još pokušavao*:
- Koristiti više verzija Cloonix-a, ali ne radi ni na njima. 
- Instalirati profesorovu verziju Cloonix-a izvan Docker okruženja, 
  ali ona zahtijeva `openssl` verziju `1.1` zbog koje bi mi se poremetile neke druge stvari, pa sam odustao od te putanje.
- Dodavati različite apparmor profile za razne Cloonix executables, ali nije bilo razlike.

Još uvijek nisam pokušavao popraviti Cloonix da radi unutar Docker okruženja jer računam da nam oko toga mogu asistenti pomoći.
Ako neko skonta bolje rješenje izvan ili unutar okruženja javite mi, pa ću dodati ovdje.
