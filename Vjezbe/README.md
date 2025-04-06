Svaka vježba je odvojena u zasebnu direktoriju.
Svaka direktorija sadrži `.md` fajl koji je opis šta i kako se radi u vježbi.
Pored `.md` fajla također imaju i `.sh` fajlovi (skripte) koji kada se izvrše naprave cijelu topologiju unutar Cloonixa,
onakvu kakva treba biti nakon što se pravilno uradi vježba.
Skripte također automatski otvore i Wireshark za svaki sniffer.
Nakon što skripta završi, u terminalu će se zelenim slovima ispisati poruka "**Done**".
Skripte se pokreću pomoću `. ./vX.sh` (`X` je broj vježbe, npr. `. ./v1.sh`) unutar containera.
Skripte se također mogu pokrenuti pomoću `./vX.sh` nakon što im se dadne executable permission sa `chmod +x vX.sh`.
