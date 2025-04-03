# auto_deploy
Auto deploy service 


1- ADDS

Static IP : Should be Set Before use the script Host-Name, edited by the script - Change it as you please

The script will proceed this way : 1 - Set Hostname / Reboot 
                                     2 - Install ADDS / Reboot 
                                       3 - Add the Forest (specified in the script) + OU

The script add an HKLM input to resume the process after the reboot, the administrator must be log manually.
/!\ In the last step (Forest settings and OU) you'll have to wait 60s (pause to let the ADDS Service start)

Run Powershell as Admin and use :
``` Powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Naxyrius/auto_deploy/refs/heads/main/ADDS_Deploy_HKLM_Version.ps1" -OutFile "C:\ADDS_Deploy_HKLM_Version.ps1"
```

Then 

```Powershell 
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\ADDS_Deploy_HKLM_Version.ps1"
```
