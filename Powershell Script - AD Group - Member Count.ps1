#
#  _  _  ___ __  __ ___  ___  ___  _____     _    ___ 
# | \| || __|\ \/ /| _ \| __|| _ \|_   _|   /_\  / __|
# |  ` || _|  >  < |  _/| _| |   /  | |    / _ \| (_ |
# |_|\_||___|/_/\_\|_|  |___||_|_\  |_|   /_/ \_\\___|
#                                                     
#-------------------
# Description:    
# Displays the number of users in a ad group
#
# Parameters:
# -ComputerName - The name of the computer you want to check for its service
# -Username: The username and the domain/computer name that applies to the target hosts
# -Password: The password for the given user.
# -Group: Name of the AD Group
#
# Example execution in powershell: 
# 'Powershell Script - AD Group - Member Count.ps1' -ComputerName server -UserName administrator -Password password -Group groupname
# 
# Example execution in PRTG:
# Copy file to PRTG probe c:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML
# Add Sensor EXE/Script Advanced
# EXE/Script Advanced Sensor Parameters: -ComputerName Server -Username %windowsuser -Password %windowspassword -Group group
# 
# WinRM needs to be enabled on the device (https://msdn.microsoft.com/en-us/library/aa384372(v=vs.85).aspx)
# Try to connect by hostname not the ip.
#
# ------------------



Param(
[string]$ComputerName = "host",
[string]$UserName = "administrator",
[string]$Password = "password",
[string]$Group = "group"
)

#create credentials 
$SecPassword = ConvertTo-SecureString $Password -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential ($UserName, $secPassword)



$ret = invoke-command -computer $ComputerName -Credential $cred -ArgumentList $Group -ScriptBlock {
Import-Module activedirectory

$Group = $args[0]

# Collect Desktop Information

$Count = (Get-ADGroup $Group -Properties *).member.count




#returning PRTG XML data
"<prtg>"
       "<result>"
       "<channel>Members</channel>"
       "<value>$Count</value>"
       "</result>"
       "<text>$Count Members</text>"
"</prtg>"

}  # end script block
$ret
