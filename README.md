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

### Komande za otvoranje sniffera sa imenom
Komanda (bash funkcija) `open_cloonix_pcap` koja se inače koristi na vježbama ima par nedostataka.
Kada se otvori jedan Wireshark, da bi se otvorio sljedeći mora se koristiti `CTRL + z`, `bg` i slično.
Dalje, teško je razlikovati Wireshark-e kada ih ima više otvorenih, u svim instancama naziv prozora je isti.

Zbog toga sam napravio naredne dvije funkcije koje možete dodati u svoj `~/.bashrc` i zatim koristiti.

Funkcija `open_pcap` radi na isti način kao i `open_cloonix_pcap`, ali popravlja navedene nedostatke.
Nije potrebno koristiti `CTRL + z` i slično, iako može tako izgledati zbog Wireshark outputa u terminalu.
Možete jednostavno odma pisati komande ili eventualno pomoću `CTRL + c` vratiti cursor ili pomoću `CTRL + l` očistiti ekran.
Na vrhu Wireshark prozora ce pisati ime sniffera za koji je on otvoren.
```bash
open_pcap ()
{
  pipe_path=/tmp
  sniffer=$(find /opt1/cloonix_data -name "*.pcap" | fzy)
  name=$(echo "$sniffer" | sed -e "s/.*\/\(.*\)\..*/\1/")
  pipe=$pipe_path/$name
  [ ! -f $pipe ] && mkfifo $pipe
  tail -f -c +0 "$sniffer" >> $pipe &
  wireshark-gtk -k -i $pipe &
}
```

Funkcija `open_sniffers` otvora sve sniffere koji su upaljeni od početka simulacije.
```bash
open_sniffers ()
{
  pipe_path=/tmp
  sniffers=$(find /opt1/cloonix_data -name "*.pcap")

  for s in $sniffers; do
    name=$(echo "$s" | sed -e "s/.*\/\(.*\)\..*/\1/")
    pipe=$pipe_path/$name
    [ ! -f $pipe ] && mkfifo $pipe
    tail -f -c +0 "$s" >> $pipe &
    wireshark-gtk -k -i $pipe &
  done
}
```

*Dodatna napomena*: \
Ako želite očistiti Wireshark output možete isključiti pa ponovo uključiti sniffer i ponovo upaliti Wireshark.


### Problem sa Cloonix-om - ne otvora se GUI
Prije pokretanja Docker okruženja (`sudo start_container`) potrebno je izvršiti komandu `xhost local:$USER`.

### [Skripta za instalaciju Cloonix-a izvan Docker okruženja](./cloonix_install.sh)
**KORISNO SAMO ZA PRVE VJEŽBE**

Za pokretanje skripte potrebno je izvršiti komandu `. ./cloonix_install.sh` (ili samo `./cloonix_install.sh` ako direktno skinete) u direktoriji u kojoj se nalazi skripta.
Skripta skine sve potrebne resurse, zatim ih odpakuje, instalira Cloonix, doda virtuelne mašine i apparmor profil.
Nakon što skripta uspješno završi ispisati će pokruku `Done`, nakon čega se ***izvan*** Docker okruženja (u *"običnom"* terminalu) pokrenuti Cloonix.

Cloonix se pokreće pomoću `cloonix_net nemo` i zatim `cloonix_gui nemo`.
Ako se pojavi poruka `Port: 45211 is in use` potrebno je izvršiti komandu `pkill cloonix-main-se`, nakon čega bi se Cloonix trebao moći pokrenuti pomoću prethodnih komandi.

Za deinstalaciju Cloonix-a potrebno je izvršiti sljedeće komande:
``` bash
sudo rm -rf /usr/bin/cloonix_*
sudo rm -rf /usr/libexec/cloonix
sudo rm -rf /var/lib/cloonix
```

**Napomena** \
Koristiti default virtuelnu mašinu (*bookworm*)
