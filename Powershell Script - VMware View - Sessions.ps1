#
#  _  _  ___ __  __ ___  ___  ___  _____     _    ___ 
# | \| || __|\ \/ /| _ \| __|| _ \|_   _|   /_\  / __|
# |  ` || _|  >  < |  _/| _| |   /  | |    / _ \| (_ |
# |_|\_||___|/_/\_\|_|  |___||_|_\  |_|   /_/ \_\\___|
#                                                     
#-------------------
# Description:    
# Displays the number of users active on vmware view pool
#
# Parameters:
# -ComputerName - The name of the computer you want to check for its service
# -Username: The username and the domain/computer name that applies to the target hosts
# -Password: The password for the given user.
# -Poolid: Name of the VMware View Pool
#
# Example execution in powershell: 
# 'Powershell Script - VMWare View - Sessions.ps1' -ComputerName Server -UserName Administrator -Password Password -Poolid poolname
# 
# Example execution in PRTG:
# Copy file to PRTG probe c:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML
# Add Sensor EXE/Script Advanced
# EXE/Script Advanced Sensor Parameters: -ComputerName Server -Username %windowsuser -Password %windowspassword -Poolid poolname
# 
# WinRM needs to be enabled on the device (https://msdn.microsoft.com/en-us/library/aa384372(v=vs.85).aspx)
# Try to connect by hostname not the ip or configure WinRM for HTTPS.
#
# Set Value Mode of the Sensor to Maximum. 
# https://kb.paessler.com/en/topic/60238-what-is-the-value-mode-in-channel-settings
#
# ------------------



Param(
[string]$ComputerName = "host",
[string]$UserName = "Administrator",
[string]$Password = "password",
[string]$Poolid = "poolid"
)

#create credentials 
$SecPassword = ConvertTo-SecureString $Password -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential ($UserName, $secPassword)



$ret = invoke-command -computer $ComputerName -Credential $cred -ArgumentList $Poolid -ScriptBlock {
Add-PSSnapin vmware.view.broker

$poolid = $args[0]

# Collect Desktop Information

$Connected = (Get-RemoteSession -pool_id $Poolid -errorAction SilentlyContinue | Where { $_.state -like "CONNECTED"} | Select state).count
$Disconnected  = (Get-RemoteSession -pool_id $Poolid -errorAction SilentlyContinue | Where { $_.state -like "DISCONNECTED"} | Select state).count
$Unreachable  = (Get-RemoteSession -pool_id $Poolid -errorAction SilentlyContinue | Where { $_.state -like "Agent unreachable"} | Select state).count
$AgentError  = (Get-RemoteSession -pool_id $Poolid -errorAction SilentlyContinue | Where { $_.state -like "Error"} | Select state).count




#returning PRTG XML data
"<prtg>"
       "<result>"
       "<channel>Connected sessions</channel>"
       "<value>$Connected</value>"
       "</result>"
       "<result>"
       "<channel>Disconnected sessions</channel>"
       "<value>$Disconnected</value>"
       "</result>"
       "<result>"
       "<channel>Error sessions</channel>"
       "<value>$AgentError</value>"
       "</result>"
       "<result>"
       "<channel>Agent unreachable sessions</channel>"
       "<value>$Unreachable</value>"
       "</result>"
       "<text>$Connected Sessions on $Poolid</text>"
"</prtg>"

}  # end script block
$ret

