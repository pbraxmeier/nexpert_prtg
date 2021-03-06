#
#  _  _  ___ __  __ ___  ___  ___  _____     _    ___ 
# | \| || __|\ \/ /| _ \| __|| _ \|_   _|   /_\  / __|
# |  ` || _|  >  < |  _/| _| |   /  | |    / _ \| (_ |
# |_|\_||___|/_/\_\|_|  |___||_|_\  |_|   /_/ \_\\___|
#                                                     
#-------------------
# Description:    
# Displays the number of Connected Network Adapters
#
# Why not using the Windows Network Card Sensor?
# Network Cards in LACP/Bionding/Teaming Mode are not visible with the Windows Network Card Sensor. Failure of one Network Card or loosing Link want be detected. 
#
#
#
# Parameters:
# -ComputerName - The name of the computer you want to check for its service
# -Username: The username and the domain/computer name that applies to the target hosts
# -Password: The password for the given user.
# #
# Example execution in powershell: 
# 'Powershell - Connected Network Adapters.ps1' -ComputerName %host -Username %windowsuser -Password %windowspassword
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
[string]$ComputerName = "host",
[string]$UserName = "Administrator",
[string]$Password = "password"
)

#create credentials 
$SecPassword = ConvertTo-SecureString $Password -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential ($UserName, $secPassword)



$ret = invoke-command -computer $ComputerName -Credential $cred -ScriptBlock {



# Collect Information
 
$m = @(Get-WmiObject -Class Win32_NetworkAdapter �filter "NetConnectionStatus = 2")
$n = $m.Count

echo $m.Name


#returning PRTG XML data
"<prtg>"
       "<result>"
       "<channel>Connected Network Adapters</channel>"
       "<value>$n</value>"
       "</result>"
"</prtg>"

}  # end script block
$ret


