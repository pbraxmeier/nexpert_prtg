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
#
# Example: 
#
#
#
# '.\Powershell Script - VMWare - Active Snapshots.ps1' -ComputerName vcenter01 -UserName domain\Administrator -Password Password -Age 30 -IgnoreList server1,server2,server3
#
# PRTG Parameters: -ComputerName %host -UserName %windowsdomain\%windowsuser -Password %windowspassword -Age 30 -IgnoreList server1,server2,server3
# 
# ------------------

Param(
[string]$ComputerName = "vcenter",
[string]$UserName = "Username",
[string]$Password = 'Password',
[string]$IgnoreList = 'server1,server2,server3',
[string]$Age = '30'
)



#create credentials 
$SecPassword = ConvertTo-SecureString $Password -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential ($UserName, $secPassword)

#Import-Module VMware.VimAutomation.Core >$Null
Import-Module "C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\VMware.VimAutomation.Sdk\VMware.VimAutomation.Sdk.psd1"
Import-Module "C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\VMware.VimAutomation.Common\VMware.VimAutomation.Common.psd1"
Import-Module "C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\VMware.VimAutomation.Cis.Core\VMware.VimAutomation.Cis.Core.psd1"
Import-Module "C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\VMware.VimAutomation.Core\VMware.VimAutomation.Core.psd1"

Connect-VIServer -Server $ComputerName -UserName $UserName -Password $Password

$global:textvar = ""

$powerstate = [string]$Args[5]
$snapshot_count = 0


$IgnoreListSplit = $IgnoreList -Split ","



Get-VM -Location $Args[4] | Get-Snapshot | Where {$IgnoreListSplit -notcontains $_.VM -and $_.Created -lt (Get-Date).AddDays(-$Age)} | `

ForEach-Object {
	$snapshot_count = $snapshot_count+1
}





function get-snaps{
    $vms = get-vm | sort name
    $vmsnaps = @()
    foreach($vm in $vms){
    	$snap = Get-Snapshot $vm | Where {$IgnoreListSplit -notcontains $_.VM -and $_.Created -lt (Get-Date).AddDays(-$Age)}
    	if($snap){
		  $vmsnaps += $vm
		  $snapshots = Get-Snapshot $vm
		  foreach ($snapshot in $snapshots){
          $global:textvar += $vm 
		  $global:textvar += "("
          $global:textvar += $snapshot.name
		  $global:textvar += "," 
		  $global:textvar += ([math]::Round($snapshot.sizemb/1024,2))
		  $global:textvar += ")"
		  $global:textvar += " - "

		}
    	}
    }
}
 
get-snaps


$x=[string]$snapshot_count+":"+$global:textvar

#write-host "$snapshot_count"

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
write-host "<text>"
write-host No Snapshots older than $Age days found
write-host "</text>"
write-host "</prtg>"


}