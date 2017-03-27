#
#  _  _  ___ __  __ ___  ___  ___  _____     _    ___ 
# | \| || __|\ \/ /| _ \| __|| _ \|_   _|   /_\  / __|
# |  ` || _|  >  < |  _/| _| |   /  | |    / _ \| (_ |
# |_|\_||___|/_/\_\|_|  |___||_|_\  |_|   /_/ \_\\___|
#                                                     
#-------------------
# Description:    
# Displays if the VMware View Pool is enabled
#
# Parameters:
# -ComputerName - The name of the computer you want to check for its service
# -Username: The username and the domain/computer name that applies to the target hosts
# -Password: The password for the given user.
# -Poolid: Name of the VMware View Pool
#
# Example execution in powershell: 
# 'Powershell Script - VMWare View - Pools Enabled.ps1' -ComputerName Server -UserName Administrator -Password Password -Poolid poolname
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
# ------------------


Param(
[string]$ComputerName = "host",
[string]$UserName = "Administrator",
[string]$Password = "password",
[string]$Poolid = "pool"
)

#create credentials 
$SecPassword = ConvertTo-SecureString $Password -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential ($UserName, $secPassword)



$ret = invoke-command -computer $ComputerName -Credential $cred -ArgumentList $Poolid -ScriptBlock {
Add-PSSnapin vmware.view.broker

$Poolid = $args[0]


$Poolenabled = (Get-Pool -pool_id $Poolid).provisionEnabled

if ($Poolenabled -eq "true") 

{
    $Result = 0
    $ResultText = "enabled"
   }
      else {
    
    $Result = 2  
    $ResultText = "disabled"
}


#returning PRTG XML data
"<prtg>"
       "<result>"
       "<channel>pool enabled</channel>"
       "<value>$Result</value>"
       "</result>"
       "<text>$Poolid is $ResultText</text>"
"</prtg>"

}  # end script block
$ret

