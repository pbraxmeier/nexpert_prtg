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
# 'Powershell Script - Skype for Business - Active calls.ps1' -ComputerName Server -UserName Administrator -Password Password
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

$ResultInbound = (Get-Counter -Counter "\LS:MediationServer - inbound calls(_total)\- current" -ErrorAction silentlycontinue).CounterSamples[0].CookedValue
$ResultOutbound = (Get-Counter -Counter "\LS:MediationServer - outbound calls(_total)\- current" -ErrorAction silentlycontinue).CounterSamples[0].CookedValue





#returning PRTG XML data
"<prtg>"
       "<result>"
       "<channel>inbound calls</channel>"
       "<value>$ResultInbound</value>"
       "</result>"
       "<result>"
       "<channel>outbound calls</channel>"
       "<value>$Resultoutbound</value>"
       "</result>"
       $TotalCalls = ($ResultInbound+$ResultOutbound)
       "<result>"
       "<channel>total calls</channel>"
       "<value>$TotalCalls</value>"
       "</result>"
       "<text>$TotalCalls active calls</text>"
"</prtg>"


}  # end script block
$ret
