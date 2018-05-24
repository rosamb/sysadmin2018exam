# sysadmin2018exam Solution
1.  script ur way to easy 3 ->> 1. first in permissions file change name of zones for urs. 2. In dns file, change corresponding hostname, and dns ip. 3. in mailconf, change the hostname and dns . 4.order of execution -> permission,dns then mailconf
2. for the firewalls i flushed (iptables -F) it to make things work. Also in the mailconf file, I have made changes to make mail work between tester and mailuser if u want to add more users, add one more lines at the end -> usermod -a -G <username> .

