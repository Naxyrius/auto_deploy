<#

Ce script PowerShell installe le rôle Active Directory Domain Services et configure certaines unités organisationnelles et groupes.

1. Vérifie si le rôle Active Directory Domain Services est déjà installé.
2. Installe le rôle Active Directory Domain Services si nécessaire.
3. Configure les OU & Groupes
V0.5
#>

# Variables
$ComputerName = "SRV-AD01"
$DomainNetbiosName = "rhoaias"
$DomainFQDN = "$DomainName.local"
$LogPath = "C:\Logs\Install-ADDS.log"

mkdir C:\Logs

$ADInstalled = Get-WindowsFeature -Name AD-Domain-Services -ErrorAction SilentlyContinue

if ($ADInstalled.Installed) {
    Write-Host "Le rôle Active Directory Domain Services est déjà installé."
} else {
    # Installer le rôle Active Directory
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -LogPath $LogPath

    # Vérifier si l'installation s'est déroulée avec succès
    if ($?) {
        Write-Host "Active Directory Domain Services a été installé avec succès."
        
        # Configuration d'Active Directory
        Import-Module ADDSDeployment
        Install-ADDSForest -CreateDnsDelegation:$false -DatabasePath "C:\Windows\NTDS" -DomainMode "WinThreshold" `
        -DomainName $DomainFQDN -DomainNetbiosName $DomainNetbiosName -ForestMode "WinThreshold" -InstallDns:$true `
        -LogPath $LogPath -NoRebootOnCompletion:$false -SysvolPath "C:\Windows\SYSVOL" -Force:$true

        # Créer des OU
        $InternalOUPath = "OU=INTERNAL,DC=rhoaias,DC=LOCAL"
        New-ADOrganizationalUnit -Name "INTERNAL" -Path $InternalOUPath
        New-ADOrganizationalUnit -Name "groupes" -Path $InternalOUPath
        New-ADOrganizationalUnit -Name "projets" -Path $InternalOUPath
        New-ADOrganizationalUnit -Name "utilisateurs" -Path $InternalOUPath
        New-ADOrganizationalUnit -Name "serveurs" -Path $InternalOUPath

        # Créer un groupe
        $GroupsOUPath = "OU=groupes,$InternalOUPath"
        New-ADGroup -Name "admins" -Description "Administrateurs" -GroupScope Global -Path $GroupsOUPath

        Write-Host "Le script s'est exécuté avec succès."
    } else {
        Write-Host "L'installation d'Active Directory a échoué."
    }
}