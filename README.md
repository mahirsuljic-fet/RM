# Računarske mreže (RM)

# Sadržaj
- [Materijal za učenje](#materijal-za-ucenje)
  - [Knjige](#knjige)
  - [Materijal sa fakulteta](#FET)
- [Skripte i rješenja problema](#skripte-i-rješenja-problema)
- [YouTube](#youtube)

# Materijal za učenje

## [Knjige](./Literatura/)
- [Computer Networks - Andrew S. Tanenbaum, 5th Edition](./Literatura/Computer Networks - 5th edition.pdf)
- [Computer Networks, a systems approach - Larry L. Peterson, 4th Edition](./Literatura/Computer Networks a systems approach - 4th edition.pdf)
- [Computer Networks, a systems approach - Larry L. Peterson, 5th Edition](./Literatura/Computer Networks a systems approach - 5th edition.pdf)
- [Computer Networks, a top down approach - James F. Kurose, 7th Edition](./Literatura/Computer Networking a top down approach - 7th edition.pdf)


## FET

### [**Predavanja**](./Predavanja)
Bilješke sa predavanja.

### [Prezentacije](./Prezentacije)
Profesorove prezentacije iz predmeta.

### [Vježbe](./Vjezbe)
Primjeri i fajlovi sa vježbi.
Također su dodane skripte koje u Cloonix-u naprave mrežu kakva treba biti kada se vježba pravilno odradi.


## YouTube

### DNS
- [DNS Explained in 100 Seconds](https://www.youtube.com/watch?v=UVR9lhUGAyU)
- [How a DNS Server (Domain Name System) works.](https://www.youtube.com/watch?v=mpQZVYPuDGU)
- [How DNS Works - Computerphile](https://www.youtube.com/watch?v=uOfonONtIuk)
- [What is DNS?](https://www.youtube.com/watch?v=NiQTs9DbtW4)


# Skripte i rješenja problema

### Problem sa Cloonix-om - ne otvora se GUI
Prije pokretanja Docker okruženja (`sudo start_container`) potrebno je izvršiti komandu `xhost +`.

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
