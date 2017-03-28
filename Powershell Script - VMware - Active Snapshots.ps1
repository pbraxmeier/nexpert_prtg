#
#  _  _  ___ __  __ ___  ___  ___  _____     _    ___ 
# | \| || __|\ \/ /| _ \| __|| _ \|_   _|   /_\  / __|
# |  ` || _|  >  < |  _/| _| |   /  | |    / _ \| (_ |
# |_|\_||___|/_/\_\|_|  |___||_|_\  |_|   /_/ \_\\___|
#                                                     
#-------------------
# Description:    
# 
# Original Script by https://kb.paessler.com/en/topic/29313-vmware-snapshots
# Modified by Nexpert AG for use with PRTG Network Monitor
#
# This script runs on the PRTG probe. Install the VMware PowerCli on the Probe. 
# Dont use powershell invoke command. further vcenter versions will be linux appliances.
#
# Example: 
#
#
#
# '.\Powershell Script - VMWare - Active Snapshots.ps1' -ComputerName vcenter01 -UserName domain\Administrator -Password Password
#
# PRTG Parameters: -ComputerName %host -UserName %windowsdomain\%windowsuser -Password %windowspassword
# If Connection to esx directly, set username and password for the device in the section linux and use the parameters
# -ComputerName %host -Username %linuxuser -Password %linuxpassword
# 
# ------------------

Param(
[string]$ComputerName = "vcenter01",
[string]$UserName = "doamin\user",
[string]$Password = 'password'
)

#create credentials 
$SecPassword = ConvertTo-SecureString $Password -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential ($UserName, $secPassword)

#Import-Module VMware.VimAutomation.Core >$Null
Import-Module "C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\VMware.VimAutomation.Sdk\VMware.VimAutomation.Sdk.psd1"
Import-Module "C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\VMware.VimAutomation.Common\VMware.VimAutomation.Common.psd1"
Import-Module "C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\VMware.VimAutomation.Cis.Core\VMware.VimAutomation.Cis.Core.psd1"
Import-Module "C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\VMware.VimAutomation.Core\VMware.VimAutomation.Core.psd1"

$global:textvar = ""


Connect-VIServer -Server $ComputerName -User $UserName -Password $Password
$powerstate = [string]$Args[5]
$snapshot_count = 0


# Collect VM Information
Get-VM -Location $Args[4] -Server $server | Get-Snapshot | `
ForEach-Object {
	$snapshot_count = $snapshot_count+1
}


function get-snaps{
    $vms = get-vm | sort name
    $vmsnaps = @()
    foreach($vm in $vms){
    	$snap = Get-Snapshot $vm
    	if($snap){
		  $vmsnaps += $vm
		  $snapshots = Get-Snapshot $vm
		  foreach ($snapshot in $snapshots){
          $global:textvar += $vm 
		  $global:textvar += " (Snapshot: "
          $global:textvar += $snapshot.name
		  $global:textvar += ", " 
		  $global:textvar += ([math]::Round($snapshot.sizemb/1024,2))
		  $global:textvar += " GB)"
		  $global:textvar += ", "

		}
    	}
    }
}
 
get-snaps


$x=[string]$snapshot_count+":"+$global:textvar

#returning PRTG XML data

if($snapshot_count -ne 0){

write-host "<prtg>"
write-host "<error>"
write-host "1"
write-host "</error>"
write-host "<text>"
write-host $global:textvar
write-host "</text>"
write-host "</prtg>"


}

if($snapshot_count -eq 0){

write-host "<prtg>"
write-host "<result>"
write-host "<channel>Snapshots running</channel>"
write-host "<value>"
write-host $snapshot_count
write-host "</value>"
write-host "<LimitMaxError>0</LimitMaxError>"
write-host "<LimitMode>1</LimitMode>"
write-host "</result>"
write-host "</prtg>"
}
