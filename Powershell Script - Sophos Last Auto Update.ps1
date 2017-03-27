#
#  _  _  ___ __  __ ___  ___  ___  _____     _    ___ 
# | \| || __|\ \/ /| _ \| __|| _ \|_   _|   /_\  / __|
# |  ` || _|  >  < |  _/| _| |   /  | |    / _ \| (_ |
# |_|\_||___|/_/\_\|_|  |___||_|_\  |_|   /_/ \_\\___|
#                                                     
#-------------------
# Description: 
#
# Displays Last update in minutes of Sophos Antivirus   
# 
# Example: 
# 
# -ComputerName %host
#
# ------------------
Param(
[string]$ComputerName = "server"
)

#create credentials 
#$SecPassword = ConvertTo-SecureString $Password -AsPlainText -Force
#$cred = new-object -typename System.Management.Automation.PSCredential ($UserName, $secPassword)
 

 
$ret = invoke-command -computer $ComputerName -ScriptBlock {

$date1=(Get-ItemProperty -Path HKLM:HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Sophos\AutoUpdate\UpdateStatus).LastUpdateTime
$date2 = (Get-Date -Date ((Get-Date ).ToUniversalTime()) -UFormat %s)
$LastUpdateTimeSeconds = [math]::Round($date2 - $date1)
$LastUpdateTimeMinute = [math]::Round($LastUpdateTimeSeconds / 60)


#returning PRTG XML data
"<prtg>"
       "<result>"
       "<channel>Last Sophos Auto Update in minutes</channel>"
       "<value>$LastUpdateTimeMinute</value>"
       "</result>"
       "<text>$LastUpdateTimeMinute minute ago on $env:computername</text>"
"</prtg>"


}  # end script block
$ret