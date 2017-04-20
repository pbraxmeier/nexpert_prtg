#
#  _  _  ___ __  __ ___  ___  ___  _____     _    ___ 
# | \| || __|\ \/ /| _ \| __|| _ \|_   _|   /_\  / __|
# |  ` || _|  >  < |  _/| _| |   /  | |    / _ \| (_ |
# |_|\_||___|/_/\_\|_|  |___||_|_\  |_|   /_/ \_\\___|
#                                                     
#-------------------
# Description:    
# 
# Displays the connected/disconnected/Agent unreachable/error VMware View Sessions per Pool
#
#
# Parameters:
# -ComputerName - The name of the computer you want to check for its service
# -Username: The username and the domain/computer name that applies to the target hosts
# -Password: The password for the given user.
# 
#
# Example execution in powershell: 
# 'Powershell Script - VMWare View - Total View Sessions.ps1' -ComputerName viewconnectionserver-UserName Administrator -Password Password
# 
# Example execution in PRTG:
# Install View PowerCli on the Vmware View connection server
# Copy file to PRTG probe c:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML
# Add Sensor EXE/Script Advanced
# EXE/Script Advanced Sensor Parameters: -ComputerName viewconnectionserver -Username %windowsuser -Password %windowspassword
# 
# WinRM needs to be enabled on the device (https://msdn.microsoft.com/en-us/library/aa384372(v=vs.85).aspx)
# Try to connect by hostname not the ip or configure WinRM for HTTPS.

Param(
[string]$ComputerName = "host",
[string]$UserName = "Administrator",
[string]$Password = "password"
)

#create credentials 
$SecPassword = ConvertTo-SecureString $Password -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential ($UserName, $secPassword)



$ret = invoke-command -computer $ComputerName -Credential $cred -ScriptBlock {
Add-PSSnapin vmware.view.broker

$Poolids = (Get-Pool).Pool_id



"<prtg>"
ForEach ($Poolid in $Poolids) {

# Collect Desktop Information

$ConnectedAll = (Get-RemoteSession -errorAction SilentlyContinue | Where { $_.state -like "CONNECTED"} | Select state).count
$Connected = (Get-RemoteSession -pool_id $Poolid -errorAction SilentlyContinue | Where { $_.state -like "CONNECTED"} | Select state).count
$Disconnected  = (Get-RemoteSession -pool_id $Poolid -errorAction SilentlyContinue | Where { $_.state -like "DISCONNECTED"} | Select state).count
$Unreachable  = (Get-RemoteSession -pool_id $Poolid -errorAction SilentlyContinue | Where { $_.state -like "Agent unreachable"} | Select state).count
$AgentError  = (Get-RemoteSession -pool_id $Poolid -errorAction SilentlyContinue | Where { $_.state -like "Error"} | Select state).count
$Provisioned = (Get-DesktopVM -pool_id $Poolid).count
$Poolenabled = (Get-Pool -pool_id $Poolid).provisionEnabled

if ($Poolenabled -eq "true") 

{
    $PoolenabledResult = 1
   }
   else {
    
    $PoolenabledResult = 2  
}



#returning PRTG XML data

       "<result>"
       "<channel>Total Connected View sessions</channel>"
       "<value>$ConnectedAll</value>"
       "</result>"
       "<result>"
       "<channel>Pool $Poolid enabled</channel>"
       "<value>$PoolenabledResult</value>"
       "<LimitMode>1</LimitMode>"	
       "<LimitMaxWarning>1</LimitMaxWarning>"
       "</result>"
       "<result>"
       "<channel>Connected sessions on $Poolid</channel>"
       "<value>$Connected</value>"
       "</result>"
       "<result>"
       "<channel>Disconnected sessions on $Poolid</channel>"
       "<value>$Disconnected</value>"
       "</result>"
       "<result>"
       "<channel>Error sessions on $Poolid</channel>"
       "<value>$AgentError</value>"
       "<LimitMode>1</LimitMode>"	
       "<LimitMaxWarning>0</LimitMaxWarning>"
       "</result>"
       "<result>"
       "<channel>Agent unreachable sessions on $Poolid</channel>"
       "<value>$Unreachable</value>"
       "<LimitMode>1</LimitMode>"	
       "<LimitMaxWarning>0</LimitMaxWarning>"
       "</result>"
       "<result>"
       "<channel>Provisioned VMs on $Poolid</channel>"
       "<value>$Provisioned</value>"
       "</result>"
       

 }
 "<text>$ConnectedAll Sessions on all pools</text>"
 "</prtg>"
}  # end script block
$ret

