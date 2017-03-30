#
#  _  _  ___ __  __ ___  ___  ___  _____     _    ___ 
# | \| || __|\ \/ /| _ \| __|| _ \|_   _|   /_\  / __|
# |  ` || _|  >  < |  _/| _| |   /  | |    / _ \| (_ |
# |_|\_||___|/_/\_\|_|  |___||_|_\  |_|   /_/ \_\\___|
#                                                     
#-------------------
# Description:    
# 
# Original Script by http://blog.fedenko.info/2017/02/prtg-vmware-datastore-monitoring.html
# Modified by Nexpert AG
#
#
# Example: 
#
#
#
# '.\Powershell Script - VMWare - Datastore Latency.ps1' -ComputerName vcenter01 -UserName domain\Administrator -Password Password
#
# PRTG Parameters: -ComputerName %host -UserName %windowsdomain\%windowsuser -Password %windowspassword
# If Connection to esx directly, set username and password for the device in the section linux and use the parameters
#
# -ComputerName %host -Username %linuxuser -Password %linuxpassword
# 
# ------------------

Param(
[string]$ComputerName = "vcenter",
[string]$UserName = "domain\username",
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

                  



# connect vCenter server session
Connect-VIServer $ComputerName -Protocol https -User $UserName -Password $Password

$Datastores = (Get-Datastore).Name



"<prtg>"
#collect data
ForEach ($Datastore in $Datastores) {

$ReadLatency=@()
$ReadLatency=Get-Datastore $Datastore | foreach {$dsName = $_.Name; $uuid = $_.ExtensionData.Info.Url.Split('/')[-2]; Get-VMHost -Datastore $_ | Get-Stat -Stat "datastore.totalReadLatency.average" -Realtime | where {$_.Instance -eq $uuid} | sort Timestamp -descending | select -first 1 | select -expand Value}


$WriteLatency=@()
$WriteLatency=Get-Datastore $Datastore | foreach {$dsName = $_.Name; $uuid = $_.ExtensionData.Info.Url.Split('/')[-2]; Get-VMHost -Datastore $_ | Get-Stat -Stat "datastore.totalWriteLatency.average" -Realtime | where {$_.Instance -eq $uuid} | sort Timestamp -descending | select -first 1 | select -expand Value}


#returning PRTG XML data

       "<result>"
       "<channel>$Datastore read latency</channel>"
       "<value>$ReadLatency</value>"
       "<Unit>Custom</Unit>"
       "<CustomUnit>ms</CustomUnit>"
       "</result>"
       "<result>"
       "<channel>$Datastore write latency</channel>"
       "<value>$WriteLatency</value>"
       "<Unit>Custom</Unit>"
       "<CustomUnit>ms</CustomUnit>"
       "</result>"


 }
 "</prtg>"