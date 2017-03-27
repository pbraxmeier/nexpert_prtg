#===========================
# ___ ___ _____ ___
#| _ \ _ \_  _/ __|
#|  _/  / | || (_ |
#|_| |_|_\ |_| \___|
#    NETWORK MONITOR
#-------------------
# Description:     This script will iterate through the windows services that are set to automatic starting and alert
#                 if they don't.
# Parameters:
# -ComputerName - The name of the computer you want to check for its service (ip is okay too)
# -IgnoreList: The services that are ignored by the script (like google update services) 
# -Username: The username and the domain/computer name that applies to the target hosts
# -Password: The password for the given user.
# Example: 
# Get-Services.ps1 -ComputerName %host -Username "%windowsdomain\%windowsuser" -Password "%windowspassword" -IgnoreList "Service1,Service2"

# ------------------
# (c) 2014 Stephan Linke | Paessler AG
param(
    [string]$ComputerName = "localhost",
    [string]$IgnoreList = "Dell Digital Delivery Service,Gruppenrichtlinienclient,Remoteregistrierung,Software Protection",
    [string]$UserName = "admin",
    [string]$Password = "password"
)

# Error if there's anything going on
$ErrorActionPreference = "Stop"

# Generate Credentials Object
$SecPasswd  = ConvertTo-SecureString $Password -AsPlainText -Force
$Credentials= New-Object System.Management.Automation.PSCredential ($UserName, $secpasswd)

# hardcoded list that applies to all hosts
$IgnoreScript = 'Google Update Service (gupdate),PRTG Probe Service'
$IgnoreCombined = @($IgnoreList) + @($IgnoreScript)

$Ignore = $IgnoreCombined -Split ","

# Get list of services that are not running, not in the ignore list and set to automatic. 
Try{ $Services = Get-WmiObject Win32_Service -ComputerName $ComputerName -Credential $Credentials | Where {$_.StartMode -eq 'Auto' -and $Ignore -notcontains $_.DisplayName -and $_.State -ne 'Running'}  }
# If the script runs for the PRTG server itself, we don't need credentials
Catch{ $Services = Get-WmiObject Win32_Service -ComputerName $ComputerName | Where {$_.StartMode -eq 'Auto' -and $Ignore -notcontains $_.DisplayName -and $_.State -ne 'Running'}  }

if($Services){
    $ServiceList = ($Services | Select -expand DisplayName) -join ", "
    if(!$Services.Count){
        Write-Host "1:Automatic service(s) not running:"$ServiceList
        exit 1
    }
    else{
    Write-Host $Services.Count":Automatic service(s) not running:"$ServiceList
    exit 1
    }
}
else{
    Write-Host "0:All automatic services are running."
    exit 0
}
#===========================