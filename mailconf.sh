#!/bin/bash

#NB! Find and replace: teacher-vm.teacher.exm, mail.teacher.exm, teacher.exm, teacher-vm 

rm /var/mail/*


#Backup vanad failid
cp -r /etc/postfix /etc/backup_postfix
cp -r /etc/dovecot /etc/backup_dovecot
cp /home/mailuser/.procmailrc  /home/mailuser/.backup_procmailrc 

#added
deluser mailuser
adduser mailuser

deluser tester
adduser tester

#Setting up NTP
apt-get update

apt-get install ntp

cat >> /etc/ntp.conf << "EOF"
server ntp.ut.ee
EOF
service ntp restart


apt-get install postfix dovecot-imapd dovecot-common procmail spamassassin alpine -y


#Check if certificates exist, if not create them
openssl req -new -x509 -days 3650 -nodes -out /etc/ssl/certs/dovecot.pem -keyout /etc/ssl/private/dovecot.key -subj "/C=EE/ST=Tartumaa/L=Tartu/O=SA Lab/CN=mail.teacher.exm"
cp /etc/ssl/certs/dovecot.pem /etc/ssl/certs/postfix.pem
cp /etc/ssl/private/dovecot.key /etc/ssl/private/postfix.key
chmod 640 /etc/ssl/private/dovecot.key
chmod 640 /etc/ssl/private/postfix.key
chgrp ssl-cert /etc/ssl/private/dovecot.key
chgrp ssl-cert /etc/ssl/private/postfix.key


cat > /etc/postfix/main.cf << "EOF"
# See /usr/share/postfix/main.cf.dist for a commented, more complete version

alias_database = hash:/etc/aliases
alias_maps = hash:/etc/aliases
append_dot_mydomain = no
biff = no
config_directory = /etc/postfix
inet_interfaces = all
inet_protocols = ipv4
mailbox_command = procmail -a "$EXTENSION"
mailbox_size_limit = 0
mydestination = teacher.exm, teacher-vm.teacher.exm, mail.teacher.exm, localhost.teacher.exm, localhost
myhostname = teacher-vm.teacher.exm
mynetworks_style = host
myorigin = $mydomain
readme_directory = no
recipient_delimiter = +
sender_canonical_maps = hash:/etc/postfix/canonical
smtp_tls_loglevel = 1
smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache
smtpd_banner = $myhostname ESMTP $mail_name (Debian/GNU)
smtpd_relay_restrictions = permit_mynetworks permit_sasl_authenticated defer_unauth_destination
smtpd_sasl_auth_enable = yes
smtpd_sasl_path = private/auth
smtpd_sasl_type = dovecot
smtpd_tls_cert_file = /etc/ssl/certs/postfix.pem
smtpd_tls_key_file = /etc/ssl/private/postfix.key
smtpd_tls_loglevel = 1
smtpd_tls_security_level = may
smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache
smtpd_use_tls = yes
EOF

cat > /etc/postfix/master.cf << "EOF"
smtp      inet  n       -       -       -       -       smtpd
submission inet n       -       -       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_sasl_path=private/auth
  -o smtpd_sasl_security_options=noanonymous
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
  -o milter_macro_daemon_name=ORIGINATING
smtps     inet  n       -       -       -       -       smtpd
  -o syslog_name=postfix/smtps
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_sasl_path=private/auth
  -o smtpd_sasl_security_options=noanonymous
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
  -o milter_macro_daemon_name=ORIGINATING
pickup    unix  n       -       -       60      1       pickup
cleanup   unix  n       -       -       -       0       cleanup
qmgr      unix  n       -       n       300     1       qmgr
tlsmgr    unix  -       -       -       1000?   1       tlsmgr
rewrite   unix  -       -       -       -       -       trivial-rewrite
bounce    unix  -       -       -       -       0       bounce
defer     unix  -       -       -       -       0       bounce
trace     unix  -       -       -       -       0       bounce
verify    unix  -       -       -       -       1       verify
flush     unix  n       -       -       1000?   0       flush
proxymap  unix  -       -       n       -       -       proxymap
proxywrite unix -       -       n       -       1       proxymap
smtp      unix  -       -       -       -       -       smtp
relay     unix  -       -       -       -       -       smtp
showq     unix  n       -       -       -       -       showq
error     unix  -       -       -       -       -       error
retry     unix  -       -       -       -       -       error
discard   unix  -       -       -       -       -       discard
local     unix  -       n       n       -       -       local
virtual   unix  -       n       n       -       -       virtual
lmtp      unix  -       -       -       -       -       lmtp
anvil     unix  -       -       -       -       1       anvil
scache    unix  -       -       -       -       1       scache
maildrop  unix  -       n       n       -       -       pipe
  flags=DRhu user=vmail argv=/usr/bin/maildrop -d ${recipient}
uucp      unix  -       n       n       -       -       pipe
  flags=Fqhu user=uucp argv=uux -r -n -z -a$sender - $nexthop!rmail ($recipient)
ifmail    unix  -       n       n       -       -       pipe
  flags=F user=ftn argv=/usr/lib/ifmail/ifmail -r $nexthop ($recipient)
bsmtp     unix  -       n       n       -       -       pipe
  flags=Fq. user=bsmtp argv=/usr/lib/bsmtp/bsmtp -t$nexthop -f$sender $recipient
scalemail-backend unix	-	n	n	-	2	pipe
  flags=R user=scalemail argv=/usr/lib/scalemail/bin/scalemail-store ${nexthop} ${user} ${extension}
mailman   unix  -       n       n       -       -       pipe
  flags=FR user=list argv=/usr/lib/mailman/bin/postfix-to-mailman.py
  ${nexthop} ${user}
EOF

#Canonical sender aliases
#touch /etc/postfix/canonical
cp /etc/postfix/canonical /etc/postfix/canonical.orgi

cat > /etc/postfix/canonical << "EOF"
@teacher-vm.teacher.exm @teacher.exm
@mail.teacher.exm  @teacher.exm
EOF

#Compile the canonical file into binary hash table: -> creates /etc/postfix/canonical.db
postmap /etc/postfix/canonical

#Dovecot
mkdir /var/log/dovecot
chown dovecot:dovecot /var/log/dovecot
chmod 640 /var/log/dovecot

cat > /etc/dovecot/conf.d/10-logging.conf << "EOF"
log_path = /var/log/dovecot/dovecot.log
mail_debug = yes
EOF

cat > /etc/dovecot/conf.d/10-ssl.conf << "EOF"
ssl = yes
ssl_cert = </etc/ssl/certs/dovecot.pem
ssl_key = </etc/ssl/private/dovecot.key
EOF

cat > /etc/dovecot/conf.d/10-auth.conf << "EOF"
#Disable login unless SSL/TLS is used
disable_plaintext_auth = yes
auth_mechanisms = plain login
!include auth-system.conf.ext
EOF

cat > /etc/dovecot/conf.d/10-mail.conf << "EOF"
mail_location = mbox:~/Mail:INBOX=/var/mail/%u
namespace inbox {
  inbox = yes
}
mail_priviledged_group = mail 
EOF

cat > /etc/dovecot/conf.d/10-master.conf << "EOF"
service auth {
#Postfix smtp-auth
  unix_listener /var/spool/postfix/private/auth {
    mode = 0666
    user = postfix
    group = postfix
  }
  }
EOF

cat > /etc/dovecot/dovecot.conf << "EOF"
!include_try /usr/share/dovecot/protocols.d/*.protocol
dict {
  #quota = mysql:/etc/dovecot/dovecot-dict-sql.conf.ext
  #expire = sqlite:/etc/dovecot/dovecot-dict-sql.conf.ext
}
!include conf.d/*.conf
!include_try local.conf
EOF


#Procmail ja Spamassassin
touch /home/mailuser/.procmailrc
chown mailuser:mailuser /home/mailuser/.procmailrc
chmod 644 /home/mailuser/.procmailrc
cat > /home/mailuser/.procmailrc << "EOF"
# SpamAssassin sample procmailrc
#
# Pipe the mail through spamassassin (replace 'spamassassin' with 'spamc'
# if you use the spamc/spamd combination)
#
# The condition line ensures that only messages smaller than 250 kB
# (250 * 1024 = 256000 bytes) are processed by SpamAssassin. Most spam
# isn't bigger than a few k and working with big messages can bring
# SpamAssassin to its knees.
#
# The lock file ensures that only 1 spamassassin invocation happens
# at 1 time, to keep the load down.
#
:0fw: spamassassin.lock
* < 256000
| spamc

# Mails with a score of 15 or higher are almost certainly spam (with 0.05%
# false positives according to rules/STATISTICS.txt). Let's put them in a
# different mbox. (This one is optional.)
:0:
* ^X-Spam-Level: \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*
mail/almost-certainly-spam

# All mail tagged as spam (eg. with a score higher than the set threshold)
# is moved to "probably-spam".
:0:
* ^X-Spam-Status: Yes
mail/probably-spam

# Work around procmail bug: any output on stderr will cause the "F" in "From"
# to be dropped.  This will re-add it.
:0
* ^^rom[ ]
{
  LOG="*** Dropped F off From_ header! Fixing up. "

  :0 fhw
  | sed -e '1s/^/F/'
}

#auto reply
LOGFILE=/home/mailuser/procmailrc.log
VERBOSE=on
#Autoreply for every incoming mail
:0 c
* !^FROM_DAEMON
* !^X-Loop: mailuser@teacher.exm
| (formail -rk -A "Precedence: junk" -A "X-Loop: mailuser@teacher.exm" ; echo "E-mail received at : " `date`) | /usr/sbin/sendmail -t -oi -oe
EOF


#Procmail ja Spamassassin
touch /home/tester/.procmailrc
chown tester:tester /home/tester/.procmailrc
chmod 644 /home/tester/.procmailrc
cat > /home/tester/.procmailrc << "EOF"
#auto reply
LOGFILE=/home/tester/procmailrc.log
VERBOSE=on
#Autoreply for every incoming mail
:0 c
* !^FROM_DAEMON
* !^X-Loop: tester@teacher.exm
| (formail -rk -A "Precedence: junk" -A "X-Loop: tester@teacher.exm" ; echo "E-mail received at : " `date`) | /usr/sbin/sendmail -t -oi -oe
EOF

#Creating Mail aliases to forward mail to mailuser
cat > /etc/aliases << EOF
postmaster:    root
root:   mailuser
user:   mailuser
EOF
#Regenerate alias database
newaliases

#Restart postfix and set to start postfix after reboot
service postfix restart
update-rc.d postfix enable

#Restart dovecot and set to start dovecot after reboot
service dovecot restart
update-rc.d dovecot enable
service dovecot status

##Restart spamassassin and set to start spamassassin after reboot
service spamassassin restart
update-rc.d spamassassin enable
service spamassassin status

#Show recent logs
#to find config error
#doveconf -n 
tail /var/log/dovecot/dovecot.log
tail /var/log/mail.log
#Test sending and receiving mail to mailuser and tester

usermod -a -G mail mailuser
usermod -a -G mail tester