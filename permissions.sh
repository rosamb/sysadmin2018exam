#!/bin/bash

# IMPORTANT: All commands from service block should be executed in exact order
# IMPORTANT: Following topics are not included: LDAP, NFS, SMB, NextCloud
# Script can be executed multiple times (for example it could be executed after TLS fix to ensure that permissions are correct)

#
# Bind
#

# Ensure that log files directory is present and all log files are present
mkdir -p /var/log/bind9
# Ensure that all log files used by bind are present
touch /var/log/bind9/update_debug.log
touch /var/log/bind9/security_info.log
touch /var/log/bind9/bind.log
# Make bind own all it's log files and ensure that permissions are correct
chown bind:bind -R /var/log/bind9
chmod 664 -R /var/log/bind9/
chmod 755 /var/log/bind9

# Set correct permissions and owner for configuration files
chgrp bind /etc/bind
chgrp bind -R /etc/bind/
chown bind:bind /etc/bind/named.conf.logging
chown bind:bind /etc/bind/rndc.key
chown bind:bind /etc/bind/zones
chmod 644 -R /etc/bind/
chmod 2755 /etc/bind
chmod 640 /etc/bind/rndc.key
chmod 2700 /etc/bind/zones

#added
chown bind:bind /etc/bind/zones/est.zone
chown bind:bind /etc/bind/zones/teacher.est.zone

#
# Certificates
#
# assign correct group for private certs
chgrp ssl-cert -R /etc/ssl/private
# set -rw-r---- for all private certs
chmod 640 -R /etc/ssl/private
chmod 750 /etc/ssl/private
# set -rw-r--r- for all normal files (our certs)
find /etc/ssl/certs -type f -exec chmod 644 {} \;

#
# Mail
#
# Ensure that permissons of postfix configuration like in labs (postfix is running under root, not important)
chmod o+r -R /etc/postfix
# Ensure that Alpine configuration has correct permissions
chmod 644 /etc/pine.conf
# Ensure that owership and permissions for dovecot configuration like in labs (dovecot is running under root, not important)
chmod o+r /etc/dovecot/dovecot.conf
chmod 644 -R /etc/dovecot/conf.d
chmod 755 /etc/dovecot/conf.d
find /etc/dovecot/*.ext -exec chmod 640 {} \;
find /etc/dovecot/*.ext -exec chgrp dovecot {} \;
# Ensure that dovecot log directory is present and has correct ownership and permissions like in labs`(dovecot is running under root, not important)
mkdir -p /var/log/dovecot
chmod 755 /var/log/dovecot

#
# Apache
#
# Ensure correct ownership of vhosts
chown www-data:www-data -R /var/www/vhosts
# Ensure that owership and permissions for apache configuration like in labs
find /etc/apache2/ -type f -exec chmod 644 {} \;
find /etc/apache2/ -type d -exec chmod 755 {} \;
# Ensure that owership and permissions for roundcube configuration like in labs
chmod 644 -R /etc/roundcube/
chmod 755 /etc/roundcube
chgrp www-data /etc/roundcube/config.inc.php
chgrp www-data /etc/roundcube/debian-db.php
chgrp www-data /etc/roundcube/config.inc.php.ucf-old
chmod 640 /etc/roundcube/config.inc.php
chmod 640 /etc/roundcube/debian-db.php
chmod 640 /etc/roundcube/config.inc.php.ucf-old
# Ensure that owership and permissions for page with showing certs like in labs
chmod 755 /usr/lib/cgi-bin/env.cgi
