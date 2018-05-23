#!/bin/bash
#DNS configuration


#to Backup vanad failid
cp -r /etc/bind /etc/bind.backup
cp /etc/hosts /etc/hosts.backup
cp /etc/resolv.conf /etc/resolv.conf.backup


#Writes text to EOF file
#Writes the contents of file
cat > /etc/bind/named.conf << "EOF"
include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.logging";
include "/etc/bind/named.conf.local";
EOF

#/etc/bind/named.conf.local
cat > /etc/bind/named.conf.local << "EOF"
view local_resolver {
match-clients { any; };
match-destinations { any; };
allow-query { any; };
recursion yes;
include "/etc/bind/named.conf.default-zones";
include "/etc/bind/zones.rfc1918";
  zone "teacher.exm" {
        type master;
        file "/etc/bind/zones/teacher.exm.zone";
  };
zone "exm" {
  type forward;
  forward only;
  forwarders {192.168.1.118;};
  };
};
view world_resolver {
include "/etc/bind/zones.rfc1918";
include "/etc/bind/named.conf.default-zones";
match-clients { any; };
match-destinations { any; };
allow-query { any; };
recursion no;
 zone "teacher.exm" {
    type master;
    file "/etc/bind/zones/teacher.exm.zone";
  };
};
EOF

#/etc/bind/named.conf.options
cat > /etc/bind/named.conf.options << "EOF"
acl goodclients{
    127.0.0.0/8;
};
options {
	directory "/var/cache/bind";

	// If there is a firewall between you and nameservers you want
	// to talk to, you may need to fix the firewall to allow multiple
	// ports to talk.  See http://www.kb.cert.org/vuls/id/800113

	// If your ISP provided one or more IP addresses for stable
	// nameservers, you probably want to use them as forwarders.
	// Uncomment the following block, and insert the addresses replacing
	// the all-0's placeholder.

	// forwarders {
	// 	0.0.0.0;
	// };

	//========================================================================
	// If BIND logs error messages about the root key being expired,
	// you will need to update your keys.  See https://www.isc.org/bind-keys
	//========================================================================
	dnssec-validation yes;
	dnssec-enable yes;

	auth-nxdomain no;    # conform to RFC1035
	listen-on { 127.0.0.1; 192.168.1.118; };
	listen-on-v6 { none; };

};

EOF
#my code from need to ask sandras
#/etc/bind/named.conf.logging
cat > /etc/bind/named.conf.logging << "EOF"
logging {
        channel update_debug {
                file "/var/log/bind9/update_debug.log" versions 3 size 100k;
                severity debug;
                print-severity  yes;
                print-time      yes;
        };
        channel security_info {
                file "/var/log/bind9/security_info.log" versions 1 size 100k;
                severity info;
                print-severity  yes;
                print-time      yes;
        };
        channel bind_log {
                file "/var/log/bind9/bind.log" versions 3 size 1m;
                severity info;
                print-category  yes;
                print-severity  yes;
                print-time      yes;
        };

        category default { bind_log; };
        category lame-servers { null; };
        category update { update_debug; };
        category update-security { update_debug; };
        category security { security_info; };
};

EOF

#/etc/bind/zones/jorge91.exm.zone
##note john and shop are site1 and site 2 as explained in lab
cat > /etc/bind/zones/teacher.exm.zone << "EOF"
$ORIGIN teacher.exm.
;
; BIND data file for local zone teacher.exm;
$TTL    15M
@       IN      SOA     ns1.teacher.exm. root.teacher.exm. (
                     2018052301         ; Serial
                            15M         ; Refresh
                             5M         ; Retry
                           120M         ; Expire
                            600 )       ; Negative Cache TTL
@                 IN      NS      ns1
@                 IN      A       192.168.1.118
ns1               IN      A       192.168.1.118
teacher-vm        IN      A       192.168.1.118
@		          IN	  MX	  10 mail
mail		      IN	  A	      192.168.1.118
www		          IN      CNAME   teacher-vm
webmail		      IN 	  CNAME   teacher-vm
monitor		      IN	  CNAME   teacher-vm
info		      IN	  CNAME   teacher-vm
test		      IN	  CNAME   teacher-vm
nextcloud         IN      CNAME   teacher-vm
EOF


#for est.zone
cat > /etc/bind/zones/exm.zone << "EOF"
;
; BIND data file for local zone teacher.exm;
$TTL    15M
@       IN      SOA     ns1.exm. root.exm. (
                     2018052301         ; Serial
                            15M         ; Refresh
                             5M         ; Retry
                           120M         ; Expire
                            600 )       ; Negative Cache TTL
@           IN      NS      ns1
@           IN      A       192.168.1.118
ns1         IN      A       192.168.1.118
;
;
; Manually added
;
teacher IN NS ns-teacher
ns-teacher IN A 192.168.1.118
EOF

#/etc/hosts
cat > /etc/hosts << "EOF"
# Your system has configured 'manage_etc_hosts' as True.
# As a result, if you wish for changes to this file to persist
# then you will need to either
# a.) make changes to the master file in /etc/cloud/templates/hosts.tmpl
# b.) change or remove the value of 'manage_etc_hosts' in
#     /etc/cloud/cloud.cfg or cloud-config from user-data
#
192.168.1.118 teacher-vm.teacher.exm teacher-vm
127.0.0.1 localhost

# The following lines are desirable for IPv6 capable hosts
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
EOF

#/etc/hostname
cat > /etc/hostname << "EOF"
teacher-vm
EOF

#/etc/resolv.conf
cat > /etc/resolv.conf << "EOF"
domain teacher.exm
search teacher.exm
nameserver 127.0.0.1
EOF

#Conf check
named-checkzone teacher.exm /etc/bind/zones/teacher.exm.zone
#If conf is correct returns nothing
named-checkzone exm /etc/bind/zones/exm.zone
#If conf is correct returns nothing
#named-checkconf

#Restart bind9 if named-checkconf returned nothing(0)
if [ $? -eq 0 ]; then
	echo "restarting bind9"
	service bind9 restart
	service bind9 status

	#Check if it works
	echo "reply should work :"
	#dig @127.0.0.1 teacher.exm
	nslookup teacher.exm
else
	echo conf check failed
fi

#Show logs
tail /var/log/bind9/bind.log
