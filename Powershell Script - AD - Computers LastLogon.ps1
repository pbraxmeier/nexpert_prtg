#
#  _  _  ___ __  __ ___  ___  ___  _____     _    ___ 
# | \| || __|\ \/ /| _ \| __|| _ \|_   _|   /_\  / __|
# |  ` || _|  >  < |  _/| _| |   /  | |    / _ \| (_ |
# |_|\_||___|/_/\_\|_|  |___||_|_\  |_|   /_/ \_\\___|
#                                                     
#-------------------
# Description:    
# 
# https://gallery.technet.microsoft.com/scriptcenter/Get-Inactive-Computer-in-54feafde
# Get inactive / old computer in your domain
# Modified by Nexpert AG for use with PRTG Network Monitor
#
#
# Example: 
#
#
#
# '.\Powershell Script - AD - Computers LastLogon.ps1' -ComputerName adserver -UserName domain\Administrator -Password Password -Age 90 -IgnoreList server1,server2,server3
#
# PRTG Parameters: -ComputerName %host -UserName %windowsdomain\%windowsuser -Password %windowspassword -Age 90 -IgnoreList server1,server2,server3
# 
# ------------------

Param(
[string]$ComputerName = "adserver",
[string]$UserName = "Username",
[string]$Password = 'Password',
[string]$IgnoreList = "server1,server2,server3",
[string]$Age = "90"
)




#create credentials 
$SecPassword = ConvertTo-SecureString $Password -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential ($UserName, $secPassword)

$ret = invoke-command -computer $ComputerName -Credential $cred -ArgumentList $IgnoreList,$Age -ScriptBlock {

$Age = "90"

$IgnoreList = $args[0]
$Age = $args[1]

$array_ignorelist = $IgnoreList.Split(",")

import-module activedirectory  

$time = (Get-Date).Adddays(-($Age)) 
  
# Get all AD computers with lastLogonTimestamp less than our time 
$OldComputer = Get-ADComputer -Filter {LastLogonTimeStamp -lt $time} -Properties LastLogonTimeStamp
$OldComputer = ($OldComputer | where-object { $_.Name -notin $array_ignorelist } | select-object Name,@{Name="Stamp"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp)}}).Name 


# Get all AD computers with lastLogonTimestamp less than our time by Count
#$Count = Get-ADComputer -Filter {LastLogonTimeStamp -lt $time} -Properties LastLogonTimeStamp
#$Count | where-object { $_.Name -notin $array_ignorelist } | select-object Name,@{Name="Stamp"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp)}}).Count 

$OldComputers = ($OldComputer -join ",")


$Count = ($OldComputer | measure).Count


#returning PRTG XML data

if($Count -gt 0){
"<prtg>"
       "<result>"
       "<channel>Count</channel>"
       "<value>$Count</value>"
       "</result>"
       "<text>$OldComputers last logon was over $Age days ago</text>"
"</prtg>"

}

if($Count -le 0){
"<prtg>"
       "<result>"
       "<channel>Count</channel>"
       "<value>$Count</value>"
       "</result>"
       "<text>OK</text>"
"</prtg>"



}  

}
# end script block
$ret


