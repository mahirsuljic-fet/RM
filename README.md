# Računarske mreže (RM)

# Sadržaj
- [Materijal za učenje](#materijal-za-ucenje)
  - [Knjige](#knjige)
  - [Materijal sa fakulteta](#FET)
  - [YouTube](#youtube)
- [Skripte i rješenja problema](#skripte-i-rješenja-problema)

<details>

<summary>Materijal za učenje</summary>

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

</details>


<details>

<summary>Skripte i rješenja problema</summary>

# Skripte i rješenja problema

<details>
<summary>Komande za otvoranje sniffera sa imenom</summary>

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

---
</details>


<details>
<summary>Konfiguracija Cloonix KVM terminala</summary>

Kolega **Irmel Haskić** je našao način da se poveća font u terminalu od KVM uređaja i napisao sljedeću skriptu:
``` bash
#!/bin/bash

cat > "$HOME/urxvt_font_setup" <<EOF
URxvt.font: xft:Monospace:size=14
URxvt.foreground: #eeeeec
URxvt.background: #300a24
EOF

if ! grep -q "cloonix_net()" "$HOME/.bashrc"; then
  cat << 'EOF' >> "$HOME/.bashrc"
cloonix_net() {
  xrdb -merge "$HOME/urxvt_font_setup"
  command cloonix_net "$@"
}
EOF
fi

source "$HOME/.bashrc"
```

Skripta radi ok, ali ima problema kada se `cloonix_net` pokreće pomoću skripti (npr. [routing.sh](./Vjezbe/v3/routing.sh)).

Slijedi rješenje koje sam smislio, a ako nekog zanima, nakon rješenja je objašnjenje zašto prvobitna skripta ne radi i kako i zašto radi novo rješenje.

Napisao sam skriptu [`setup_cloonix_conf.sh`](./setup_cloonix_conf.sh) koja radi sve što treba za novo rješenje.
Unutar skripte možete promijeniti naziv i path do fajla u koji želite pisati konfiguraciju.

<details>
<summary>Novije rješenje</summary>
<br>

Ovo rješenje čita konfiguracijske podatke iz fajla `~/.cloonix_conf`.
Potrebno je ove dvije linije koda unutar funkcije `cloonix_net` iz orginalne skripte upisati u fajl `~/.local/bin/cloonix_net` uz neke izmjene:
``` bash
xrdb -merge $HOME/.cloonix_conf
. /usr/local/bin/cloonix_net "$@"
```
Ovom fajlu je potrebno dati executable permisije pomoću `chmox +x ~/.local/bin/cloonix_net`.

Unutar fajla `.cloonix_conf` je potrebno dodati konfiguracijske podatke kao npr.:
```
urxvt.font: xft:Monospace:size=14
urxvt.foreground: #eeeeee
urxvt.background: #222222
```

Font se mijenja u formatu `xft:IME_FONTA:size=VELICINA`.
Ako želite neki drugi font, možete unutar KVM terminala izvrsiti komandu `fc-list` koja će ispisati instalirane fontove.
`foreground` je boja slova, a `background` je boja pozadine, u hex RGB formatu 
(prve dvije hex cifre su nivo crvene boje, druge dvije nivo zelene i zadnje dvije nivo plave boje).

Možete također napraviti providnu pozadinu pomoću rgba (red-green-blue-alpha) formata kao:
```
urxvt.font: xft:Monospace:size=14
urxvt.foreground: #eeeeee
urxvt.depth: 32
urxvt.background: rgba:0000/0000/2222/cccc
```

Prvi dio je ponovo za crvenu boju, drugi za zelenu, treći za plavu i četvrti dio predstavlja providnost gdje je `0000` skroz providno, a `ffff` nikako providno.
Potrebno je također dodati `depth` parametar.

---
</details>

<details>
<summary>Opis novijeg rješenja</summary>
<br>

Prvobitno rješenje ne radi zato jer bash skripte ne vide funkcije definisane u `~/.bashrc`.
Ovo se naivno može riješiti na dva načina.
Prvi je da se unutar svake skripte definise funkcija `cloonix_net` (copy-paste),
a drugi je da se unutar svake skripte source-a `~/.bashrc`.
Međutim, ovo bi morali uraditi za svaku skriptu, što je realno previše posla.

Rješenje koje sam smislio iskoristava način na koji bash traži executable fajlove.
Kada napišemo nesto u terminalu, bash pretražuje `$PATH` varijablu za lokacije gdje bi se taj fajl 
(npr. `ls` je executable fajl `/usr/bin/ls`) mogao nalaziti, i to prioritet imaju putanje koje su na početku PATH-a. 
Jedna od putanja u `$PATH` je `/home/$USER/.local/bin`. 
Ova putanja je lokalna (dio korisnikovih fajlova, ne utiče na cijeli sistem), unutar skrivene `.local` direktorije (tako da ne smeta) i najbitnije dio je `$PATH`-a od okruženja.

Dakle, ako unutar `/home/$USER/.local/bin` (naše putanje) napravimo executable fajl sa imenom `cloonix_net`, 
on će se izvrsiti prije "običnog" `cloonix_net`-a koji se nalazi u `/usr/local/bin/` jer se ta putanja nalazi posle naše u `$PATH`. 
Tako da možemo upravo to i uraditi tako što napravimo novi fajl `cloonix_net` u našoj putanji i dadnemo mu executable permisije pomoću `chmod` (ne radi bez permisija).

---
</details>

---
</details>

<details>

<summary>Problem sa Cloonix-om - ne otvora se GUI</summary>
<br>

Prije pokretanja Docker okruženja (`sudo start_container`) potrebno je izvršiti komandu `xhost local:$USER`.

---
</details>


<details>
<summary>Skripta za instalaciju Cloonix-a izvan Docker okruženja</summary>
<br>

**KORISNO SAMO ZA PRVE VJEŽBE**

[skripta](./cloonix_install.sh)

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
Koristiti default virtuelnu mašinu (*bookworm*).

---
</details>
