#!/bin/bash

mkdir -p /root/rps-migrate

# New copy of discovery output
curl script.prosrv.us/discovery.sh | bash > /root/rps-migrate/discovery.src

# Make migration RSA key
ssh-keygen -t rsa -b 4096 -f /root/rps-migrate/id_rsa_migrate

# Disk Infos
du -a / | sort -n -r | head -n 10 >> /root/rps-migrate/du.src


iptables-save > /root/rps-migrate/iptables.rules.src

# Pull stuff from /etc
mkdir -p /root/rps-migrate/etc.src
for file in apache2 httpd yum* shadow passwd group gshadow host* iptable* network* sysconfig cron* dovecot postfix ssh
  do cp -a /etc/$file /root/rps-migrate/etc.src/$file.src
done

# Pull Yum stuff
mkdir -p /root/rps-migrate/yuminfo
yum repolist enabled >> /root/rps-migrate/yuminfo/yumrepos.txt
grep -Er '^exclude' /etc/yum* > /root/rps-migrate/yuminfo/yum.excludes
rpm -qa  --queryformat '%{NAME}\n' 2>&1 | sort -u  >> /root/rps-migrate/yuminfo/yum.installed.src
cp -a /etc/yum.repos.d /root/rps-migrate/yuminfo/.
cp /etc/yum.conf /root/rps-migrate/yuminfo/.
yum repolist enabled >> yumrepos.enabled.src > /root/rps-migrate/yuminfo/repos.enabled.src

# Users
# https://access.redhat.com/solutions/179753
mkdir -p /root/rps-migrate/user.src/bkup.orig
ID_minimum=500
for file in passwd group gshadow shadow ; do cp /etc/$file /root/rps-migrate/user.src/bkup.orig/$file.src ; done
for f in /etc/{passwd,group}; do awk -F: -vID=$ID_minimum '$3>=ID && $1!="nfsnobody"' $f |sort -nt: -k3 > /root/rps-migrate/user.src/${f#/etc/}.bak; done
while read line; do grep "^${line%%:*}" /etc/shadow; done </root/rps-migrate/user.src/passwd.bak > /root/rps-migrate/user.src/shadow.bak
while read line; do grep "^${line%%:*}" /etc/gshadow; done </root/rps-migrate/user.src/group.bak >/root/rps-migrate/user.src/gshadow.bak

# On dest:
# for f in {passwd,group,shadow,gshadow}.bak; do cat $f >>/etc/${f%.bak}; done
# for uidgid in $(cut -d: -f3,4 passwd.bak); do
#    dir=$(awk -F: /$uidgid/{print\$6} passwd.bak)
#    mkdir -vm700 "$dir"; cp -r /etc/skel/.[[:alpha:]]* "$dir"
#    chown -R $uidgid "$dir"; ls -ld "$dir"
#done
