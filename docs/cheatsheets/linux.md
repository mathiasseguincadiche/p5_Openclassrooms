# 📋 Cheatsheet Linux

**Bienvenue dans le cheatsheet Linux !**
Cette page regroupe les **commandes Linux les plus utiles** pour les débutants et les utilisateurs avancés.

---

## 📌 Table des Matières

1. [Système](#systeme)
2. [Fichiers et Dossiers](#-fichiers-et-dossiers)
3. [Permissions](#-permissions)
4. [Processus](#-processus)
5. [Réseau](#-réseau)
6. [Utilisateurs et Groupes](#-utilisateurs-et-groupes)
7. [Disques et Stockage](#-disques-et-stockage)
8. [Paquets](#-paquets)
9. [Textes et Fichiers](#-textes-et-fichiers)
10. [Archives](#archives)
11. [SSH](#-ssh)
12. [Cron](#-cron)
13. [Dépannage](#depannage)

---

<a id="systeme"></a>

## 🖥️ Système

| Commande | Description | Exemple |
|----------|-------------|---------|
| `uname -a` | Afficher les informations du système | `uname -a` |
| `hostname` | Afficher le nom de la machine | `hostname` |
| `hostnamectl` | Afficher les informations de l'hôte (systemd) | `hostnamectl` |
| `uptime` | Afficher le temps de fonctionnement | `uptime` |
| `date` | Afficher la date et l'heure | `date` |
| `cal` | Afficher un calendrier | `cal` |
| `whoami` | Afficher l'utilisateur actuel | `whoami` |
| `id` | Afficher l'ID de l'utilisateur | `id` |
| `pwd` | Afficher le répertoire courant | `pwd` |
| `echo $SHELL` | Afficher le shell actuel | `echo $SHELL` |
| `echo $PATH` | Afficher le PATH | `echo $PATH` |
| `env` | Afficher toutes les variables d'environnement | `env` |
| `set` | Afficher toutes les variables (y compris shell) | `set` |
| `exit` | Quitter le shell | `exit` |
| `shutdown` | Éteindre la machine | `sudo shutdown -h now` |
| `reboot` | Redémarrer la machine | `sudo reboot` |
| `clear` | Effacer le terminal | `clear` |
| `history` | Afficher l'historique des commandes | `history` |
| `!!` | Répéter la dernière commande | `!!` |
| `!<n>` | Répéter la commande n | `!42` |
| `Ctrl + R` | Rechercher dans l'historique | `Ctrl + R` puis tapez un mot |
| `Ctrl + C` | Interrompre une commande | `Ctrl + C` |
| `Ctrl + Z` | Mettre en pause une commande | `Ctrl + Z` |
| `fg` | Reprendre une commande en pause | `fg` |
| `bg` | Mettre en arrière-plan une commande en pause | `bg` |
| `jobs` | Lister les jobs en arrière-plan | `jobs` |

---

## 📁 Fichiers et Dossiers

### Navigation

| Commande | Description | Exemple |
|----------|-------------|---------|
| `ls` | Lister les fichiers et dossiers | `ls` |
| `ls -l` | Lister avec détails | `ls -l` |
| `ls -la` | Lister tous les fichiers (y compris cachés) | `ls -la` |
| `ls -lh` | Lister avec tailles lisibles | `ls -lh` |
| `ls -lt` | Lister par date de modification | `ls -lt` |
| `ls -lS` | Lister par taille | `ls -lS` |
| `cd <dir>` | Changer de répertoire | `cd /home/user` |
| `cd ..` | Remonter d'un niveau | `cd ..` |
| `cd ~` | Aller dans le répertoire personnel | `cd ~` |
| `cd -` | Aller dans le répertoire précédent | `cd -` |
| `mkdir <dir>` | Créer un dossier | `mkdir mon-dossier` |
| `mkdir -p <dir1>/<dir2>` | Créer des dossiers imbriqués | `mkdir -p mon-dossier/sous-dossier` |

### Manipulation

| Commande | Description | Exemple |
|----------|-------------|---------|
| `touch <file>` | Créer un fichier vide | `touch mon-fichier.txt` |
| `cp <source> <dest>` | Copier un fichier | `cp fichier.txt /backup/` |
| `cp -r <source> <dest>` | Copier un dossier (récursif) | `cp -r mon-dossier /backup/` |
| `mv <source> <dest>` | Déplacer ou renommer un fichier | `mv fichier.txt nouveau-nom.txt` |
| `rm <file>` | Supprimer un fichier | `rm fichier.txt` |
| `rm -r <dir>` | Supprimer un dossier (récursif) | `rm -r mon-dossier` |
| `rm -f <file>` | Supprimer un fichier (forcé) | `rm -f fichier.txt` |
| `rmdir <dir>` | Supprimer un dossier vide | `rmdir mon-dossier` |
| `cat <file>` | Afficher le contenu d'un fichier | `cat fichier.txt` |
| `less <file>` | Afficher le contenu page par page | `less fichier.txt` |
| `more <file>` | Afficher le contenu page par page | `more fichier.txt` |
| `head <file>` | Afficher les 10 premières lignes | `head fichier.txt` |
| `head -n <n> <file>` | Afficher les n premières lignes | `head -n 20 fichier.txt` |
| `tail <file>` | Afficher les 10 dernières lignes | `tail fichier.txt` |
| `tail -n <n> <file>` | Afficher les n dernières lignes | `tail -n 20 fichier.txt` |
| `tail -f <file>` | Suivre les modifications d'un fichier | `tail -f /var/log/syslog` |

### Recherche

| Commande | Description | Exemple |
|----------|-------------|---------|
| `find <dir> -name <name>` | Trouver des fichiers par nom | `find /home -name "*.txt"` |
| `find <dir> -type f` | Trouver des fichiers | `find /home -type f` |
| `find <dir> -type d` | Trouver des dossiers | `find /home -type d` |
| `find <dir> -mtime -<n>` | Trouver des fichiers modifiés il y a moins de n jours | `find /home -mtime -7` |
| `find <dir> -size +<size>` | Trouver des fichiers par taille | `find /home -size +10M` |
| `grep <pattern> <file>` | Rechercher un motif dans un fichier | `grep "erreur" /var/log/syslog` |
| `grep -r <pattern> <dir>` | Rechercher un motif récursivement | `grep -r "erreur" /var/log/` |
| `grep -i <pattern> <file>` | Rechercher un motif (insensible à la casse) | `grep -i "erreur" fichier.txt` |
| `grep -v <pattern> <file>` | Rechercher les lignes qui ne contiennent pas le motif | `grep -v "erreur" fichier.txt` |
| `grep -n <pattern> <file>` | Rechercher avec numéros de ligne | `grep -n "erreur" fichier.txt` |
| `grep -A <n> <pattern> <file>` | Afficher n lignes après le motif | `grep -A 5 "erreur" fichier.txt` |
| `grep -B <n> <pattern> <file>` | Afficher n lignes avant le motif | `grep -B 5 "erreur" fichier.txt` |
| `grep -C <n> <pattern> <file>` | Afficher n lignes avant et après le motif | `grep -C 5 "erreur" fichier.txt` |
| `locate <file>` | Trouver un fichier (base de données mise à jour avec `updatedb`) | `locate fichier.txt` |
| `which <command>` | Trouver le chemin d'une commande | `which ls` |
| `whereis <command>` | Trouver le chemin d'une commande (binaire, man, etc.) | `whereis ls` |

---

## 🔐 Permissions

| Commande | Description | Exemple |
|----------|-------------|---------|
| `chmod <mode> <file>` | Changer les permissions d'un fichier | `chmod 755 script.sh` |
| `chmod +x <file>` | Ajouter le droit d'exécution | `chmod +x script.sh` |
| `chmod -x <file>` | Supprimer le droit d'exécution | `chmod -x script.sh` |
| `chmod -R <mode> <dir>` | Changer les permissions récursivement | `chmod -R 755 mon-dossier` |
| `chown <user>:<group> <file>` | Changer le propriétaire d'un fichier | `chown user:group fichier.txt` |
| `chown -R <user>:<group> <dir>` | Changer le propriétaire récursivement | `chown -R user:group mon-dossier` |
| `chgrp <group> <file>` | Changer le groupe d'un fichier | `chgrp group fichier.txt` |
| `umask` | Afficher le umask actuel | `umask` |
| `umask <mask>` | Définir un nouveau umask | `umask 022` |

### Permissions Numériques

| Permission | Valeur | Description |
|------------|--------|-------------|
| `0` | `---` | Aucune permission |
| `1` | `--x` | Exécution |
| `2` | `-w-` | Écriture |
| `3` | `-wx` | Écriture + Exécution |
| `4` | `r--` | Lecture |
| `5` | `r-x` | Lecture + Exécution |
| `6` | `rw-` | Lecture + Écriture |
| `7` | `rwx` | Lecture + Écriture + Exécution |

### Exemples de Permissions

| Commande | Description |
|----------|-------------|
| `chmod 755 fichier` | `rwxr-xr-x` (propriétaire : rwx, groupe : r-x, autres : r-x) |
| `chmod 644 fichier` | `rw-r--r--` (propriétaire : rw-, groupe : r--, autres : r--) |
| `chmod 600 fichier` | `rw-------` (propriétaire : rw-, groupe : ---, autres : ---) |
| `chmod 777 fichier` | `rwxrwxrwx` (tous : rwx) |

---

## 🔄 Processus

| Commande | Description | Exemple |
|----------|-------------|---------|
| `ps` | Lister les processus | `ps` |
| `ps aux` | Lister tous les processus | `ps aux` |
| `ps -ef` | Lister tous les processus (format étendu) | `ps -ef` |
| `ps -u <user>` | Lister les processus d'un utilisateur | `ps -u user` |
| `ps -p <pid>` | Afficher les informations d'un processus | `ps -p 1234` |
| `pstree` | Afficher les processus sous forme d'arbre | `pstree` |
| `top` | Afficher les processus en temps réel | `top` |
| `htop` | Afficher les processus en temps réel (amélioré) | `htop` |
| `kill <pid>` | Terminer un processus | `kill 1234` |
| `kill -9 <pid>` | Forcer la terminaison d'un processus | `kill -9 1234` |
| `killall <name>` | Terminer tous les processus avec un nom | `killall nginx` |
| `pkill <name>` | Terminer les processus par nom | `pkill nginx` |
| `pgrep <name>` | Trouver l'ID d'un processus par nom | `pgrep nginx` |
| `nice -n <priority> <command>` | Lancer une commande avec une priorité | `nice -n 10 command` |
| `renice <priority> -p <pid>` | Changer la priorité d'un processus | `renice 10 -p 1234` |
| `bg` | Mettre un processus en arrière-plan | `bg` |
| `fg` | Reprendre un processus en avant-plan | `fg` |
| `jobs` | Lister les jobs en arrière-plan | `jobs` |

---

## 🌐 Réseau

| Commande | Description | Exemple |
|----------|-------------|---------|
| `ifconfig` | Afficher les interfaces réseau | `ifconfig` |
| `ip a` | Afficher les interfaces réseau (moderne) | `ip a` |
| `ip addr` | Afficher les adresses IP | `ip addr` |
| `ip route` | Afficher la table de routage | `ip route` |
| `ping <host>` | Tester la connectivité | `ping google.com` |
| `ping -c <n> <host>` | Tester la connectivité avec n paquets | `ping -c 4 google.com` |
| `traceroute <host>` | Tracer la route vers un hôte | `traceroute google.com` |
| `mtr <host>` | Combinaison de ping et traceroute | `mtr google.com` |
| `nslookup <host>` | Résoudre un nom d'hôte | `nslookup google.com` |
| `dig <host>` | Résoudre un nom d'hôte (plus détaillé) | `dig google.com` |
| `host <host>` | Résoudre un nom d'hôte | `host google.com` |
| `curl <url>` | Télécharger ou afficher une URL | `curl https://google.com` |
| `curl -O <url>` | Télécharger un fichier | `curl -O https://example.com/file.zip` |
| `curl -o <file> <url>` | Télécharger un fichier avec un nom spécifique | `curl -o file.zip https://example.com/file.zip` |
| `curl -I <url>` | Afficher les en-têtes HTTP | `curl -I https://google.com` |
| `wget <url>` | Télécharger un fichier | `wget https://example.com/file.zip` |
| `wget -O <file> <url>` | Télécharger un fichier avec un nom spécifique | `wget -O file.zip https://example.com/file.zip` |
| `wget -r <url>` | Télécharger récursivement | `wget -r https://example.com` |
| `netstat -tuln` | Afficher les connexions réseau | `netstat -tuln` |
| `ss -tuln` | Afficher les connexions réseau (moderne) | `ss -tuln` |
| `lsof -i :<port>` | Afficher les processus utilisant un port | `lsof -i :80` |
| `nc -zv <host> <port>` | Tester une connexion TCP | `nc -zv google.com 80` |
| `telnet <host> <port>` | Tester une connexion TCP (interactif) | `telnet google.com 80` |

---

## 👥 Utilisateurs et Groupes

| Commande | Description | Exemple |
|----------|-------------|---------|
| `useradd <user>` | Ajouter un utilisateur | `sudo useradd john` |
| `useradd -m <user>` | Ajouter un utilisateur avec un répertoire personnel | `sudo useradd -m john` |
| `useradd -s <shell> <user>` | Ajouter un utilisateur avec un shell spécifique | `sudo useradd -s /bin/bash john` |
| `usermod -aG <group> <user>` | Ajouter un utilisateur à un groupe | `sudo usermod -aG sudo john` |
| `passwd <user>` | Changer le mot de passe d'un utilisateur | `sudo passwd john` |
| `userdel <user>` | Supprimer un utilisateur | `sudo userdel john` |
| `userdel -r <user>` | Supprimer un utilisateur et son répertoire personnel | `sudo userdel -r john` |
| `groupadd <group>` | Ajouter un groupe | `sudo groupadd developers` |
| `groupdel <group>` | Supprimer un groupe | `sudo groupdel developers` |
| `groups <user>` | Afficher les groupes d'un utilisateur | `groups john` |
| `id <user>` | Afficher l'ID d'un utilisateur | `id john` |
| `who` | Afficher les utilisateurs connectés | `who` |
| `w` | Afficher les utilisateurs connectés et leurs processus | `w` |
| `last` | Afficher l'historique des connexions | `last` |
| `sudo <command>` | Exécuter une commande en tant que root | `sudo apt update` |
| `su <user>` | Changer d'utilisateur | `su john` |

---

## 💾 Disques et Stockage

| Commande | Description | Exemple |
|----------|-------------|---------|
| `df -h` | Afficher l'espace disque | `df -h` |
| `df -hT` | Afficher l'espace disque avec le type de système de fichiers | `df -hT` |
| `du -sh <dir>` | Afficher la taille d'un dossier | `du -sh /home` |
| `du -sh *` | Afficher la taille de tous les fichiers/dossiers | `du -sh *` |
| `fdisk -l` | Lister les disques et partitions | `sudo fdisk -l` |
| `lsblk` | Lister les disques et partitions (arbre) | `lsblk` |
| `blkid` | Afficher les UUID des partitions | `sudo blkid` |
| `mount` | Afficher les systèmes de fichiers montés | `mount` |
| `mount <device> <dir>` | Monter un système de fichiers | `sudo mount /dev/sdb1 /mnt` |
| `umount <dir>` | Démonter un système de fichiers | `sudo umount /mnt` |
| `mkfs <type> <device>` | Formater un disque | `sudo mkfs.ext4 /dev/sdb1` |
| `fsck <device>` | Vérifier un système de fichiers | `sudo fsck /dev/sdb1` |
| `dd if=<source> of=<dest>` | Copier un disque ou un fichier | `dd if=/dev/sdb of=/dev/sdc` |
| `dd if=/dev/zero of=<file> bs=<size> count=<n>` | Créer un fichier vide | `dd if=/dev/zero of=file.img bs=1M count=100` |

---

## 📦 Paquets

### Debian/Ubuntu (APT)

| Commande | Description | Exemple |
|----------|-------------|---------|
| `sudo apt update` | Mettre à jour la liste des paquets | `sudo apt update` |
| `sudo apt upgrade` | Mettre à jour les paquets installés | `sudo apt upgrade` |
| `sudo apt install <package>` | Installer un paquet | `sudo apt install nginx` |
| `sudo apt install -y <package>` | Installer un paquet sans confirmation | `sudo apt install -y nginx` |
| `sudo apt remove <package>` | Supprimer un paquet | `sudo apt remove nginx` |
| `sudo apt purge <package>` | Supprimer un paquet et ses fichiers de configuration | `sudo apt purge nginx` |
| `sudo apt autoremove` | Supprimer les paquets inutilisés | `sudo apt autoremove` |
| `sudo apt clean` | Nettoyer le cache des paquets | `sudo apt clean` |
| `sudo apt search <package>` | Rechercher un paquet | `sudo apt search nginx` |
| `sudo apt show <package>` | Afficher les informations d'un paquet | `sudo apt show nginx` |
| `dpkg -l` | Lister les paquets installés | `dpkg -l` |
| `dpkg -l "*<pattern>"` | Lister les paquets avec un motif | `dpkg -l "*nginx*"` |
| `dpkg -s <package>` | Afficher les informations d'un paquet | `dpkg -s nginx` |
| `dpkg -L <package>` | Lister les fichiers d'un paquet | `dpkg -L nginx` |

### RHEL/CentOS (YUM/DNF)

| Commande | Description | Exemple |
|----------|-------------|---------|
| `sudo yum update` | Mettre à jour les paquets | `sudo yum update` |
| `sudo yum install <package>` | Installer un paquet | `sudo yum install nginx` |
| `sudo yum remove <package>` | Supprimer un paquet | `sudo yum remove nginx` |
| `sudo yum search <package>` | Rechercher un paquet | `sudo yum search nginx` |
| `sudo yum info <package>` | Afficher les informations d'un paquet | `sudo yum info nginx` |
| `sudo yum clean all` | Nettoyer le cache des paquets | `sudo yum clean all` |
| `rpm -qa` | Lister les paquets installés | `rpm -qa` |
| `rpm -qa "*<pattern>"` | Lister les paquets avec un motif | `rpm -qa "*nginx*"` |
| `rpm -qi <package>` | Afficher les informations d'un paquet | `rpm -qi nginx` |
| `rpm -ql <package>` | Lister les fichiers d'un paquet | `rpm -ql nginx` |

### Arch Linux (Pacman)

| Commande | Description | Exemple |
|----------|-------------|---------|
| `sudo pacman -Syu` | Mettre à jour les paquets | `sudo pacman -Syu` |
| `sudo pacman -S <package>` | Installer un paquet | `sudo pacman -S nginx` |
| `sudo pacman -R <package>` | Supprimer un paquet | `sudo pacman -R nginx` |
| `sudo pacman -Ss <package>` | Rechercher un paquet | `sudo pacman -Ss nginx` |
| `sudo pacman -Qi <package>` | Afficher les informations d'un paquet | `sudo pacman -Qi nginx` |
| `sudo pacman -Ql <package>` | Lister les fichiers d'un paquet | `sudo pacman -Ql nginx` |
| `sudo pacman -Qdt` | Lister les dépendances orphelines | `sudo pacman -Qdt` |
| `sudo pacman -Rns $(pacman -Qdtq)` | Supprimer les dépendances orphelines | `sudo pacman -Rns $(pacman -Qdtq)` |

### Snap

| Commande | Description | Exemple |
|----------|-------------|---------|
| `sudo snap install <package>` | Installer un paquet Snap | `sudo snap install spotify` |
| `sudo snap remove <package>` | Supprimer un paquet Snap | `sudo snap remove spotify` |
| `snap list` | Lister les paquets Snap installés | `snap list` |
| `snap info <package>` | Afficher les informations d'un paquet Snap | `snap info spotify` |
| `sudo snap refresh` | Mettre à jour les paquets Snap | `sudo snap refresh` |

---

## 📄 Textes et Fichiers

| Commande | Description | Exemple |
|----------|-------------|---------|
| `cat <file>` | Afficher le contenu d'un fichier | `cat fichier.txt` |
| `tac <file>` | Afficher le contenu d'un fichier à l'envers | `tac fichier.txt` |
| `nl <file>` | Afficher le contenu avec numéros de ligne | `nl fichier.txt` |
| `wc <file>` | Compter les lignes, mots et caractères | `wc fichier.txt` |
| `wc -l <file>` | Compter les lignes | `wc -l fichier.txt` |
| `wc -w <file>` | Compter les mots | `wc -w fichier.txt` |
| `wc -c <file>` | Compter les caractères | `wc -c fichier.txt` |
| `sort <file>` | Trier les lignes d'un fichier | `sort fichier.txt` |
| `sort -r <file>` | Trier les lignes à l'envers | `sort -r fichier.txt` |
| `sort -n <file>` | Trier numériquement | `sort -n fichier.txt` |
| `uniq <file>` | Supprimer les lignes dupliquées | `uniq fichier.txt` |
| `uniq -c <file>` | Compter les occurrences des lignes | `uniq -c fichier.txt` |
| `cut -d<delim> -f<n> <file>` | Extraire une colonne | `cut -d',' -f1 fichier.csv` |
| `awk '{print $1}' <file>` | Extraire la première colonne | `awk '{print $1}' fichier.txt` |
| `sed 's/<old>/<new>/g' <file>` | Remplacer du texte | `sed 's/foo/bar/g' fichier.txt` |
| `sed -i 's/<old>/<new>/g' <file>` | Remplacer du texte et modifier le fichier | `sed -i 's/foo/bar/g' fichier.txt` |
| `tr <from> <to>` | Remplacer des caractères | `echo "hello" \| tr 'a-z' 'A-Z'` |
| `paste <file1> <file2>` | Fusionner des fichiers | `paste fichier1.txt fichier2.txt` |
| `join <file1> <file2>` | Joindre des fichiers sur une colonne commune | `join -1 1 -2 1 fichier1.txt fichier2.txt` |
| `diff <file1> <file2>` | Afficher les différences entre deux fichiers | `diff fichier1.txt fichier2.txt` |
| `diff -u <file1> <file2>` | Afficher les différences unifiées | `diff -u fichier1.txt fichier2.txt` |
| `patch <file> <patch>` | Appliquer un patch | `patch fichier.txt mon-patch.patch` |

---

<a id="archives"></a>

## 🗜️ Archives

| Commande | Description | Exemple |
|----------|-------------|---------|
| `tar -cvf <file.tar> <dir>` | Créer une archive tar | `tar -cvf archive.tar /home/user` |
| `tar -xvf <file.tar>` | Extraire une archive tar | `tar -xvf archive.tar` |
| `tar -czvf <file.tar.gz> <dir>` | Créer une archive tar.gz | `tar -czvf archive.tar.gz /home/user` |
| `tar -xzvf <file.tar.gz>` | Extraire une archive tar.gz | `tar -xzvf archive.tar.gz` |
| `tar -cjvf <file.tar.bz2> <dir>` | Créer une archive tar.bz2 | `tar -cjvf archive.tar.bz2 /home/user` |
| `tar -xjvf <file.tar.bz2>` | Extraire une archive tar.bz2 | `tar -xjvf archive.tar.bz2` |
| `gzip <file>` | Compresser un fichier | `gzip fichier.txt` |
| `gunzip <file.gz>` | Décompresser un fichier | `gunzip fichier.txt.gz` |
| `bzip2 <file>` | Compresser un fichier (bzip2) | `bzip2 fichier.txt` |
| `bunzip2 <file.bz2>` | Décompresser un fichier (bzip2) | `bunzip2 fichier.txt.bz2` |
| `zip -r <file.zip> <dir>` | Créer une archive zip | `zip -r archive.zip /home/user` |
| `unzip <file.zip>` | Extraire une archive zip | `unzip archive.zip` |
| `7z a <file.7z> <dir>` | Créer une archive 7z | `7z a archive.7z /home/user` |
| `7z x <file.7z>` | Extraire une archive 7z | `7z x archive.7z` |

---

## 🔑 SSH

| Commande | Description | Exemple |
|----------|-------------|---------|
| `ssh <user>@<host>` | Se connecter à un serveur | `ssh user@192.168.1.10` |
| `ssh -p <port> <user>@<host>` | Se connecter sur un port spécifique | `ssh -p 2222 user@192.168.1.10` |
| `ssh -i <key> <user>@<host>` | Se connecter avec une clé SSH | `ssh -i ~/.ssh/id_rsa user@192.168.1.10` |
| `ssh-keygen` | Générer une nouvelle clé SSH | `ssh-keygen -t rsa -b 4096` |
| `ssh-keygen -t <type> -b <bits>` | Générer une clé SSH d'un type spécifique | `ssh-keygen -t ed25519` |
| `ssh-copy-id <user>@<host>` | Copier une clé SSH sur un serveur | `ssh-copy-id user@192.168.1.10` |
| `ssh-add <key>` | Ajouter une clé SSH à l'agent | `ssh-add ~/.ssh/id_rsa` |
| `ssh-agent` | Démarrer l'agent SSH | `eval $(ssh-agent -s)` |
| `ssh-config` | Configurer SSH | `nano ~/.ssh/config` |
| `scp <file> <user>@<host>:<path>` | Copier un fichier via SSH | `scp fichier.txt user@192.168.1.10:/home/user/` |
| `scp -r <dir> <user>@<host>:<path>` | Copier un dossier via SSH | `scp -r mon-dossier user@192.168.1.10:/home/user/` |
| `sftp <user>@<host>` | Se connecter via SFTP | `sftp user@192.168.1.10` |

### Exemple de `~/.ssh/config`

```
Host mon-serveur
  HostName 192.168.1.10
  User user
  Port 22
  IdentityFile ~/.ssh/id_rsa
```

---

## ⏰ Cron

| Commande | Description | Exemple |
|----------|-------------|---------|
| `crontab -e` | Éditer la crontab de l'utilisateur actuel | `crontab -e` |
| `crontab -l` | Lister la crontab de l'utilisateur actuel | `crontab -l` |
| `crontab -r` | Supprimer la crontab de l'utilisateur actuel | `crontab -r` |
| `sudo crontab -e` | Éditer la crontab de root | `sudo crontab -e` |
| `sudo service cron start` | Démarrer le service cron | `sudo service cron start` |
| `sudo service cron stop` | Arrêter le service cron | `sudo service cron stop` |
| `sudo service cron restart` | Redémarrer le service cron | `sudo service cron restart` |

### Syntaxe Crontab

```
# Minute Heure Jour Mois Jour_de_la_semaine Commande
# 0-59   0-23 1-31 1-12 0-6 (0=dimanche)

# Exemples :
0 * * * * /path/to/command  # Toutes les heures
*/10 * * * * /path/to/command  # Toutes les 10 minutes
0 0 * * * /path/to/command  # Tous les jours à minuit
0 0 * * 0 /path/to/command  # Tous les dimanches à minuit
0 0 1 * * /path/to/command  # Le premier jour de chaque mois à minuit
0 0 1 1 * /path/to/command  # Le 1er janvier à minuit
0 0 13 * 5 /path/to/command  # Tous les vendredis 13 à minuit

# Rediriger la sortie :
0 * * * * /path/to/command > /path/to/log.txt 2>&1
```

---

<a id="depannage"></a>

## 🛠️ Dépannage

| Problème | Solution | Commande |
|----------|----------|----------|
| `Permission denied` | Problème de permissions | `chmod +x script.sh` ou `sudo` |
| `No such file or directory` | Fichier ou dossier introuvable | Vérifiez le chemin |
| `Command not found` | Commande introuvable | Vérifiez le PATH ou installez la commande |
| `Disk quota exceeded` | Quota disque dépassé | `df -h` et supprimez des fichiers |
| `Too many open files` | Trop de fichiers ouverts | `ulimit -n 2048` |
| `Connection refused` | Connexion refusée | Vérifiez que le service est en cours d'exécution |
| `No route to host` | Aucune route vers l'hôte | Vérifiez le réseau |
| `Segmentation fault` | Erreur de segmentation | Vérifiez le code ou les bibliothèques |
| `Broken pipe` | Pipe cassée | Ignorez ou gérez l'erreur |

---

## 📚 Ressources

- [Commandes Linux de Base](https://linuxcommand.org/tlcl.php)
- [Linux Journey](https://linuxjourney.com/)
- [OverTheWire Bandit](https://overthewire.org/wargames/bandit/) (pour apprendre Linux en pratiquant)
- [ExplainShell](https://explainshell.com/) (pour comprendre les commandes)

---

**Bonne utilisation de Linux !** 🐧
