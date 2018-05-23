# sysadmin2018exam
# [3:45 PM, 5/23/2018] Rohin Gts: I have patched jorge's dns and postfix and tested multiple times in my snapshot. script ur way to easy 3 ->> 1. first in permissions file change name of zones for urs. 2. In dns file, change corresponding hostname, and dns ip. 3. in mailconf, change the hostname and dns . 4.order of execution -> permission,dns then mailconf
[3:49 PM, 5/23/2018] Rohin Gts: for the firewalls i flushed (iptables -F) it to make things work. Also in the mailconf file, I have made changes to make mail work between tester and debian if u want to add more users, add one more lines at the end -> usermod -a -G <username> .
[3:49 PM, 5/23/2018] Rohin Gts: tester and *mailuser
