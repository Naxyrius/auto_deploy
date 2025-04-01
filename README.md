# auto_deploy
Script d'automatisations de déploiements de services

Ports  : 53 - TCP/UDP DNS
         88 - TCP/UDP Kerberos
         389 - TCP/UDP - LDAP
 
1 - Hostname 
```powershell
Rename-Computer -NewName SRV-AD01 -Force
Restart-Computer
```

2- Config Réseau

``` Powershell
New-NetIPAddress -IPAddress "192.168.1.10" -PrefixLength "24" -InterfaceIndex (Get-NetAdapter).ifIndex -DefaultGateway "192.168.1.1"
```

DNS

``` Powershell 
Set-DnsClientServerAddress -InterfaceIndex (Get-NetAdapter).ifIndex -ServerAddresses ("127.0.0.1")
```

Si besoin : rename adaptateur réseau 

``` Powershell 
Rename-NetAdapter -Name Ethernet0 -NewName LAN
```
