#
#  _  _  ___ __  __ ___  ___  ___  _____     _    ___ 
# | \| || __|\ \/ /| _ \| __|| _ \|_   _|   /_\  / __|
# |  ` || _|  >  < |  _/| _| |   /  | |    / _ \| (_ |
# |_|\_||___|/_/\_\|_|  |___||_|_\  |_|   /_/ \_\\___|
#                                                     
#-------------------
# Description:    
# Displays the Skype for Business Active Calls
#
# Parameters:
# -ComputerName - The name of the computer you want to check for its service
# -Username: The username and the domain/computer name that applies to the target hosts
# -Password: The password for the given user.
#
# Example execution in powershell: 
# 'Powershell Script - Skype for Business - Active user count.ps1' -ComputerName Server -UserName Administrator -Password Password
# 
# Example execution in PRTG:
# Copy file to PRTG probe c:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML
# Add Sensor EXE/Script Advanced
# EXE/Script Advanced Sensor Parameters: -ComputerName Server -Username %windowsuser -Password %windowspassword
# 
# WinRM needs to be enabled on the device (https://msdn.microsoft.com/en-us/library/aa384372(v=vs.85).aspx)
# Try to connect by hostname not the ip.
#
# ------------------
Param(
[string]$ComputerName = "server",
[string]$UserName = "username",
[string]$Password = "password"
)

#create credentials 
$SecPassword = ConvertTo-SecureString $Password -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential ($UserName, $secPassword)



$ret = invoke-command -computer $ComputerName -Credential $cred -ScriptBlock {

$Result = (Get-Counter "\LS:SIP - Peers(Clients)\SIP - Connections Active").CounterSamples[0].CookedValue





#returning PRTG XML data
"<prtg>"
       "<result>"
       "<channel>Active user count</channel>"
       "<value>$Result</value>"
       "</result>"
       "<text>$Result Active users</text>"
"</prtg>"


}  # end script block
$ret
