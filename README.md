# auto_deploy
Script d'automatisations de déploiements de services

Ports : 53 - TCP/UDP DNS 88 - TCP/UDP Kerberos 389 - TCP/UDP - LDAP

IP Fixe : Should be Set Before use the script Host-Name, edited by the script - Change it as you please

The script will proceed this way : 1 - Set Hostname / Reboot 2 - Install ADDS / Reboot 3 - Add the Forest (specified in the script) + OU

The script add an HKLM input to resume the process after the reboot, the administrator must be log manually.
/!\ In the last step (Forest settings and OU) you'll have to wait 60s (pause to let the ADDS Service start)