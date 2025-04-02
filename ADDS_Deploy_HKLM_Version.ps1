<#
Ce script PowerShell installe le rôle Active Directory Domain Services, configure une forêt Active Directory,
et crée des unités organisationnelles (OUs).
Auth: Naxyrius 02/04/25
Ajout : Journalisation des erreurs dans le dossier Logs et correction du nom du script
#>

# Variables
$ComputerName = "SRV-AD01"                     # Nom du serveur
$DomainNetbiosName = "rhoaias"                 # Nom NetBIOS du domaine
$DomainFQDN = "rhoaias.local"                  # FQDN du domaine
$LogPath = "C:\Logs"                           # Chemin du dossier log
$ErrorLogPath = "$LogPath\ErrorLog.txt"        # Fichier de log des erreurs
$ScriptPath = "C:\ADDS_Deploy_HKLM_Version.ps1" # Chemin local pour le script
$FlagFilePathRename = "C:\RenameCompleted.flag" # Fichier de drapeau pour gérer le renommage
$FlagFilePathRole = "C:\RoleInstalled.flag"     # Fichier de drapeau pour gérer l'installation du rôle
$FlagFilePathForest = "C:\ForestConfigured.flag" # Fichier de drapeau pour gérer la configuration de la forêt
$RegistryKeyPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
$RegistryValueName = "ContinueADSetup"

# Créer le dossier Logs si nécessaire
mkdir $LogPath -Force

# Fonction pour journaliser les erreurs (renommée avec un verbe approuvé)
function Write-ErrorLog {
    param (
        [string]$Message
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $ErrorLogPath -Value "$Timestamp - ERROR: $Message"
}

# Étape 1 : Configurer une clé de registre pour reprendre après redémarrage
try {
    if (-not (Test-Path "$RegistryKeyPath\$RegistryValueName")) {
        Write-Host "Création d'une clé de registre pour continuer après redémarrage..."
        Set-ItemProperty -Path $RegistryKeyPath -Name $RegistryValueName -Value "PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
    }
} catch {
    Write-ErrorLog "Échec lors de la création de la clé de registre : $_"
}

# Étape 2 : Gestion du renommage et redémarrage
try {
    if (-not (Test-Path $FlagFilePathRename)) {
        if ($env:COMPUTERNAME -ne $ComputerName) {
            Write-Host "Renommage du serveur en $ComputerName..."
            Rename-Computer -NewName $ComputerName -Force -Restart

            New-Item $FlagFilePathRename
            exit
        }
    }
} catch {
    Write-ErrorLog "Échec lors du renommage du serveur : $_"
}

# Étape 3 : Installer le rôle AD DS et gérer le redémarrage
try {
    if (-not (Test-Path $FlagFilePathRole)) {
        if (-not (Get-WindowsFeature AD-Domain-Services).Installed) {
            Write-Host "Installation du rôle Active Directory Domain Services..."
            Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

            New-Item $FlagFilePathRole
            Restart-Computer
            exit
        }
    }
} catch {
    Write-ErrorLog "Échec lors de l'installation du rôle AD DS : $_"
}

# Étape 4 : Configuration de la forêt Active Directory et promotion en contrôleur de domaine
try {
    if (-not (Test-Path $FlagFilePathForest)) {
        Write-Host "Configuration de la forêt Active Directory..."
        mkdir C:\Logs -Force

        Install-ADDSForest `
            -DomainName $DomainFQDN `
            -DomainNetbiosName $DomainNetbiosName `
            -DatabasePath "$env:SystemDrive\NTDS" `
            -SysvolPath "$env:SystemDrive\SYSVOL" `
            -LogPath "$LogPath\Install-ADDS.log" `
            -SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force) `
            -InstallDns:$true `
            -Force:$true
        
        Write-Host "Redémarrage requis après configuration de la forêt."
        Restart-Computer

        New-Item $FlagFilePathForest
        exit  # Quitte le script pour permettre un redémarrage propre.
    }
} catch {
    Write-ErrorLog "Échec lors de la configuration de la forêt Active Directory : $_"
}

# Étape 5 : Pause pour permettre aux services AD de démarrer correctement
try {
    Write-Host "Attente des services Active Directory..."
    Start-Sleep 60
} catch {
    Write-ErrorLog "Erreur pendant l'attente des services AD : $_"
}

# Étape 6 : Vérifier et créer les OUs si elles n'existent pas déjà
try {
    Import-Module ActiveDirectory

    $RootOUPath = "DC=rhoaias,DC=local"
    if (-not (Get-ADOrganizationalUnit -Filter {Name -eq 'CORE'})) {
        New-ADOrganizationalUnit -Name "CORE" -Path $RootOUPath
    }
    if (-not (Get-ADOrganizationalUnit -Filter {Name -eq 'HUMANS'})) {
        New-ADOrganizationalUnit -Name "HUMANS" -Path $RootOUPath
    }
    if (-not (Get-ADOrganizationalUnit -Filter {Name -eq 'ADMINS'})) {
        New-ADOrganizationalUnit -Name "ADMINS" -Path $RootOUPath
    }
    if (-not (Get-ADOrganizationalUnit -Filter {Name -eq 'Users'})) {
        New-ADOrganizationalUnit -Name "Users" -Path $RootOUPath
    }

    Write-Host "Les unités organisationnelles ont été créées."
} catch {
    Write-ErrorLog "Erreur lors de la création des unités organisationnelles : $_"
}

# Supprimer la clé de registre à la fin de l'installation si tout est terminé avec succès.
try {
    if (Test-Path "$RegistryKeyPath\$RegistryValueName") {
        Remove-ItemProperty -Path $RegistryKeyPath -Name $RegistryValueName
    }
} catch {
    Write-ErrorLog "Erreur lors de la suppression de la clé de registre : $_"
}

Write-Host "Le script s'est exécuté avec succès."
