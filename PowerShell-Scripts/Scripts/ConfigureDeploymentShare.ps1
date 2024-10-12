# *************************************************************************** 
# 
# File:      ConfigureDeploymentShare.ps1 
# 
# Author:    Rens Hollanders 
# 
# Purpose:   This PowerShell script will configure your entire deploymentshare 
#            Bootstrap.ini and CustomSettings.ini are completely overwritten
#            The DeploymentShare properties in Settings.xml are modfied
#            
#            Note that there should be no one actively adding items to the 
#            deployment share while running this script, as some of the 
#            operations performed could cause these items to be lost. 
# 
#            This requires PowerShell 2.0 CTP3 or later. 
# 
# Usage:     Copy this file to an appropriate location.  Edit the file to 
#            change the variables below.
# 
# ------------- DISCLAIMER -------------------------------------------------- 
# This script code is provided as is with no guarantee or warranty concerning 
# the usability or impact on systems and may be used, distributed, and 
# modified in any way provided the parties agree and acknowledge the 
# Microsoft or Microsoft Partners have neither accountability or 
# responsibility for results produced by use of this script. 
# 
# Microsoft will not provide any support through any means. 
# ------------- DISCLAIMER -------------------------------------------------- 
# 
# **************************************************************************

# Constants

# Specify General DeploymentShare Properties
$PSDrive = "DS001:"
$UNCPath = "\\ServerName\DeploymentShare$"
$PhysicalPath = "D:\DeploymentShare"
$Hostname = "ServerName"
$Description = "MDT Deployment Share"

# Specify Bootstrap.ini Properties
$UserDomain = "Domain"
$UserID = "sa-mdtconnect"
$UserPassword = "P@ssw0rd"

# Specify CustomSettings.ini Properties
# Specify Task Sequence Personalization
$SMSTSOrgName = "Organization Name"
$SMSTSPackageName = "%TaskSequenceName%"

# Specify Domain Join Information
$JoinWorkgroup = "WORKGROUP"
$JoinDomain = "Domain"
$DomainAdmin = "JoinAccount"
$DomainAdminDomain = "Domain"
$DomainAdminPassword = "P@ssw0rd"
$MachineObjectOU = "OU=staging,OU=workstationsDC=Domain,DC=local"

#Specify ComputerBackupLocation
$ComputerBackupLocation = "%DEPLOYROOT%\Captures\%COMPUTERNAME%"
$BackupFile = "W7SP1ENTx64EN.wim"

# Specify WSUSServer
$WSUSServer = "http://hostname.domain.com:8530"

# Bootstrap.ini Properties
$BStext = @"
[Settings]
Priority=Default

[Default]
DeployRoot=$UNCPath

UserDomain=$UserDomain
UserID=$UserID
UserPassword=$UserPassword

KeyboardLocale=en-US
SkipBDDWelcome=YES"@

# CustomSettings.ini Properties
$CStext = @"
[Settings]
Priority=Model, Default
Properties=MyCustomProperty

; Hyper-V
[Virtual Machine]
_SMSTSPackageName=$SMSTSPackageName
TaskSequenceID=OSB001
OSDComputerName=OSBUILD
JoinWorkgroup=$JoinWorkgroup
; Computer Backup Location
DoCapture=YES
ComputerBackupLocation=$ComputerBackupLocation
BackupFile=$BackupFile
; Finish Action
FinishAction=SHUTDOWN

; VMware
[VMware Virtual Platform]
_SMSTSPackageName=$SMSTSPackageName
TaskSequenceID=OSB001
OSDComputerName=$JoinWorkgroup
JoinWorkgroup=BUILD
; Computer Backup Location
DoCapture=YES
ComputerBackupLocation=$ComputerBackupLocation
BackupFile=$BackupFile
; Finish Action
FinishAction=SHUTDOWN

[Default]
_SMSTSOrgName=$SMSTSOrgName
_SMSTSPackageName=$SMSTSPackageName
OSInstall=YES
SkipAdminPassword=YES
SkipBitLocker=YES
SkipCapture=YES
SkipComputerBackup=YES
SkipComputerName=YES
OSDComputerName=%SerialNumber%
SkipDomainMembership=YES
SkipLocaleSelection=YES
SkipProductKey=YES
SkipRoles=YES
SkipSummary=YES
SkipTaskSequence=YES
TaskSequenceID=OSD001
SkipTimeZone=YES
SkipUserData=YES
SkipFinalSummary=YES
FinishAction=REBOOT

; Domain Join Configuration
JoinDomain=$JoinDomain
DomainAdmin=$DomainAdmin
DomainAdminDomain=$DomainAdminDomain
DomainAdminPassword=$DomainAdminPassword
MachineObjectOU=$MachineObjectOU

; Regional and Locale Settings
TimeZoneName=W. Europe Standard Time
KeyboardLocale=nl-NL;0413:00000409
UserLocale=nl-NL
UILanguage=nl-NL

; Display Settings
BitsPerPel=32
VRefresh=60
XResolution=1
YResolution=1

; Hide Windows Shell during deployment
HideShell=YES

; WSUS Server
WSUSServer=$WSUSServer

; EXCLUDED WSUS UPDATES for Windows 7
;Microsoft Browser Choice Screen Update for EEA Users of Windows 7 for x64-based Systems (KB976002)
WUMU_ExcludeKB1=976002
;Microsoft Silverlight (KB2636927)
WUMU_ExcludeKB2=2636927
;Windows Internet Explorer 9 for Windows 7 for x64-based Systems (KB982861)
WUMU_ExcludeKB3=982861
;Windows Internet Explorer 10 for Windows 7 for x64-based Systems (KB2718695)
WUMU_ExcludeKB4=2718695
;Bing Desktop (KB2694771)
WUMU_ExcludeKB5=2694771

; EXCLUDED WSUS UPDATES for Windows 8/8.1
; Microsoft Silverlight (KB2668562)
WUMU_ExcludeKB6=2668562
; Microsoft Browser Choice Screen Update for EEA Users of Windows 8 for x64-based Systems (KB976002)
WUMU_ExcludeKB7=976002
; Update for Internet Explorer Flash Player for Windows 8 for x64-based Systems (KB2824670)
WUMU_ExcludeKB8=2824670

; Logging and Monitoring
SLShareDynamicLogging=%DEPLOYROOT%\Logs\%COMPUTERNAME%
EventService=http://$Hostname:9800
"@

# Check for elevation
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "You need to run this script from an elevated PowerShell prompt!`nPlease start the PowerShell prompt as an Administrator and re-run the script."
    Write-Warning "Aborting script..."
    Break
}

# Get Start Time
$startDTM = (Get-Date)

# Import the Microsoft Deployment Toolkit Powershell Module
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"

# Create New-PSDrive
MD $PhysicalPath
New-PSDrive -Name ($PSdrive -replace(":","")) -PSProvider MDTProvider -Root "$PhysicalPath" -Description "$Description" -NetworkPath "$UNCPath" | add-MDTPersistentDrive

# Wait for 5 seconds to let the sample files to be copied to the new deployment share
Start-Sleep -s 5

# Configure Deployment Share Properties

# Configure General Deployment Share Properties
Set-ItemProperty -Path "$PSDrive" -Name Comments  -Value 'Version 1.0 of Automatic Configuration using ConfigureDeploymentShare.ps1'
Set-ItemProperty -Path "$PSDrive" -Name EnableMulticast -Value $False
Set-ItemProperty -Path "$PSDrive" -Name SupportX86 -Value $False
Set-ItemProperty -Path "$PSDrive" -Name SupportX64 -Value $True
Set-ItemProperty -Path "$PSDrive" -Name UNCPath -Value "$UNCPath"
Set-ItemProperty -Path "$PSDrive" -Name PhysicalPath -Value "$PhysicalPath"
Set-ItemProperty -Path "$PSDrive" -Name MonitorHost -Value "$Hostname"
Set-ItemProperty -Path "$PSDrive" -Name MonitorEventPort -Value '9800'
Set-ItemProperty -Path "$PSDrive" -Name MonitorDataPort -Value '9801'

# Configure x86 boot image Deployment Share Properties
Set-ItemProperty -Path "$PSDrive" -Name Boot.x86.UseBootWim -Value $False
Set-ItemProperty -Path "$PSDrive" -Name Boot.x86.ScratchSpace -Value '32'
Set-ItemProperty -Path "$PSDrive" -Name Boot.x86.IncludeAllDrivers -Value $True
Set-ItemProperty -Path "$PSDrive" -Name Boot.x86.IncludeNetworkDrivers -Value $False
Set-ItemProperty -Path "$PSDrive" -Name Boot.x86.IncludeMassStorageDrivers -Value $False
Set-ItemProperty -Path "$PSDrive" -Name Boot.x86.IncludeVideoDrivers -Value $False
Set-ItemProperty -Path "$PSDrive" -Name Boot.x86.IncludeSystemDrivers -Value $False
Set-ItemProperty -Path "$PSDrive" -Name Boot.x86.BackgroundFile -Value '%DEPLOYROOT%\Extra\Background.png'
Set-ItemProperty -Path "$PSDrive" -Name Boot.x86.ExtraDirectory -Value '%DEPLOYROOT%\Extra'
Set-ItemProperty -Path "$PSDrive" -Name Boot.x86.GenerateGenericWIM -Value $False
Set-ItemProperty -Path "$PSDrive" -Name Boot.x86.GenerateGenericISO -Value $False
Set-ItemProperty -Path "$PSDrive" -Name Boot.x86.GenericWIMDescription -Value 'Generic Windows PE (x86)'
Set-ItemProperty -Path "$PSDrive" -Name Boot.x86.GenericISOName -Value 'Generic_x86.iso'
Set-ItemProperty -Path "$PSDrive" -Name Boot.x86.GenerateLiteTouchISO -Value $False
Set-ItemProperty -Path "$PSDrive" -Name Boot.x86.LiteTouchWIMDescription -Value 'Lite Touch Windows PE (x86)'
Set-ItemProperty -Path "$PSDrive" -Name Boot.x86.LiteTouchISOName -Value 'LiteTouchPE_x86.iso'
Set-ItemProperty -Path "$PSDrive" -Name Boot.x86.SelectionProfile -Value 'Drivers_WinPE_x86'
Set-ItemProperty -Path "$PSDrive" -Name Boot.x86.SupportUEFI -Value $True
Set-ItemProperty -Path "$PSDrive" -Name Boot.x86.FeaturePacks -Value 'winpe-mdac'

# Configure x64 boot image Deployment Share Properties
Set-ItemProperty -Path "$PSDrive" -Name Boot.x64.UseBootWim -Value $False
Set-ItemProperty -Path "$PSDrive" -Name Boot.x64.ScratchSpace -Value '32'
Set-ItemProperty -Path "$PSDrive" -Name Boot.x64.IncludeAllDrivers -Value $True
Set-ItemProperty -Path "$PSDrive" -Name Boot.x64.IncludeNetworkDrivers -Value $False
Set-ItemProperty -Path "$PSDrive" -Name Boot.x64.IncludeMassStorageDrivers -Value $False
Set-ItemProperty -Path "$PSDrive" -Name Boot.x64.IncludeVideoDrivers -Value $False
Set-ItemProperty -Path "$PSDrive" -Name Boot.x64.IncludeSystemDrivers -Value $False
Set-ItemProperty -Path "$PSDrive" -Name Boot.x64.BackgroundFile -Value '%DEPLOYROOT%\Extra\Background.png'
Set-ItemProperty -Path "$PSDrive" -Name Boot.x64.ExtraDirectory -Value '%DEPLOYROOT%\Extra'
Set-ItemProperty -Path "$PSDrive" -Name Boot.x64.GenerateGenericWIM -Value $False
Set-ItemProperty -Path "$PSDrive" -Name Boot.x64.GenerateGenericISO -Value $False
Set-ItemProperty -Path "$PSDrive" -Name Boot.x64.GenericWIMDescription -Value 'Generic Windows PE (x64)'
Set-ItemProperty -Path "$PSDrive" -Name Boot.x64.GenericISOName -Value 'Generic_x64.iso'
Set-ItemProperty -Path "$PSDrive" -Name Boot.x64.GenerateLiteTouchISO -Value $True
Set-ItemProperty -Path "$PSDrive" -Name Boot.x64.LiteTouchWIMDescription -Value 'Lite Touch Windows PE (x64)'
Set-ItemProperty -Path "$PSDrive" -Name Boot.x64.LiteTouchISOName -Value 'LiteTouchPE_x64.iso'
Set-ItemProperty -Path "$PSDrive" -Name Boot.x64.SelectionProfile -Value 'Drivers_WinPE_x64'
Set-ItemProperty -Path "$PSDrive" -Name Boot.x64.SupportUEFI -Value $True
Set-ItemProperty -Path "$PSDrive" -Name Boot.x64.FeaturePacks -Value 'winpe-mdac'

# Configure Database Deployment Share Properties
Set-ItemProperty -Path "$PSDrive" -Name Database.SQLServer -Value ''
Set-ItemProperty -Path "$PSDrive" -Name Database.Instance -Value ''
Set-ItemProperty -Path "$PSDrive" -Name Database.Port -Value ''
Set-ItemProperty -Path "$PSDrive" -Name Database.Netlib -Value ''
Set-ItemProperty -Path "$PSDrive" -Name Database.Name -Value ''
Set-ItemProperty -Path "$PSDrive" -Name Database.SQLShare -Value ''

# Configure Bootstrap.ini and CustomSettings.ini
# Set Bootstrap.ini and Customsettings.ini properties
Set-Content -Path "$PhysicalPath\Control\Bootstrap.ini" -value $BSText
Set-Content -Path "$PhysicalPath\Control\CustomSettings.ini" -value $CSText

# Configure Scripts
# Replace "Lite Touch Installation" with variable so that _SMSTSPackageName can be used
Set-Content -path "$PhysicalPath\Scripts\LiteTouch.wsf" -Value ((Get-Content -Path "$PhysicalPath\Scripts\LiteTouch.wsf") -replace ('"Lite Touch Installation"','oEnvironment.Item("TaskSequenceName")'))
# Replace the value of 1000 for 1024 to calculate hard disk partitions in binary size
Set-Content -path "$PhysicalPath\Scripts\ZTIDiskpart.wsf" -Value ((Get-Content -Path "$PhysicalPath\Scripts\ZTIDiskpart.wsf") -replace ('PartitionSize \* 1000','PartitionSize * 1024'))

# Configure Deployment Workbench Folder Structure
# Create Application Folders
New-Item -Path "$PSDrive\Applications" -enable "True" -Name "Hardware Specific Applications" -Comments "" -ItemType "folder"
New-Item -Path "$PSDrive\Applications" -enable "True" -Name "Supporting Applications" -Comments "" -ItemType "folder"
New-Item -Path "$PSDrive\Applications" -enable "True" -Name "Office Applications" -Comments "" -ItemType "folder"
New-Item -Path "$PSDrive\Applications" -enable "True" -Name "Business Applications" -Comments "" -ItemType "folder"
New-Item -Path "$PSDrive\Applications" -enable "True" -Name "Clients & Agents" -Comments "" -ItemType "folder"

# Create Operating System Platform Folders
New-Item -Path "$PSDrive\Operating Systems" -enable "True" -Name "Windows 7 x64" -Comments "" -ItemType "folder"
New-Item -Path "$PSDrive\Operating Systems" -enable "True" -Name "Windows 8.1 x64" -Comments "" -ItemType "folder"
New-Item -Path "$PSDrive\Operating Systems" -enable "True" -Name "Server 2008(R2) x64" -Comments "" -ItemType "folder"
New-Item -Path "$PSDrive\Operating Systems" -enable "True" -Name "Server 2012(R2) x64" -Comments "" -ItemType "folder"

# Create Operating System Platform Source and Product Folders
New-Item -Path "$PSDrive\Operating Systems\Windows 7 x64" -enable "True" -Name "Source" -Comments "" -ItemType "folder"
New-Item -Path "$PSDrive\Operating Systems\Windows 7 x64" -enable "True" -Name "Product" -Comments "" -ItemType "folder"
New-Item -Path "$PSDrive\Operating Systems\Windows 8.1 x64" -enable "True" -Name "Source" -Comments "" -ItemType "folder"
New-Item -Path "$PSDrive\Operating Systems\Windows 8.1 x64" -enable "True" -Name "Product" -Comments "" -ItemType "folder"
New-Item -Path "$PSDrive\Operating Systems\Server 2008(R2) x64" -enable "True" -Name "Source" -Comments "" -ItemType "folder"
New-Item -Path "$PSDrive\Operating Systems\Server 2008(R2) x64" -enable "True" -Name "Product" -Comments "" -ItemType "folder"
New-Item -Path "$PSDrive\Operating Systems\Server 2012(R2) x64" -enable "True" -Name "Source" -Comments "" -ItemType "folder"
New-Item -Path "$PSDrive\Operating Systems\Server 2012(R2) x64" -enable "True" -Name "Product" -Comments "" -ItemType "folder"

# Create WinPE x64 and x86 Folders in Out-of-Box Drivers
New-Item -Path "$PSDrive\Out-of-Box Drivers" -enable "True" -Name "WinPE" -Comments "" -ItemType "folder"
New-Item -path "$PSDrive\Out-of-Box Drivers\WinPE" -enable "True" -Name "x64" -Comments "" -ItemType "folder"
New-Item -path "$PSDrive\Out-of-Box Drivers\WinPE" -enable "True" -Name "x86" -Comments "" -ItemType "folder"

# Create Virtual Folders for Hypervisors in Out-of-Box Drivers
New-Item -Path "$PSDrive\Out-of-Box Drivers\" -enable "True" -Name "Virtual" -Comments "" -ItemType "folder"
New-Item -Path "$PSDrive\Out-of-Box Drivers\Virtual" -enable "True" -Name "Hyper-V" -Comments "" -ItemType "folder"
New-Item -Path "$PSDrive\Out-of-Box Drivers\Virtual" -enable "True" -Name "VMware" -Comments "" -ItemType "folder"

# Create Platform Folders in Out-of-Box Drivers Folders
New-Item -Path "$PSDrive\Out-of-Box Drivers" -enable "True" -Name "Windows 7 x64" -Comments "" -ItemType "folder"
New-Item -Path "$PSDrive\Out-of-Box Drivers" -enable "True" -Name "Windows 8.1 x64" -Comments "" -ItemType "folder"

# Create Sub-Folders in Packages Folders
New-Item -Path "$PSDrive\Packages" -enable "True" -Name "Windows 7 x64" -Comments "" -ItemType "folder"
New-Item -Path "$PSDrive\Packages" -enable "True" -Name "Windows 8.1 x64" -Comments "" -ItemType "folder"
New-Item -Path "$PSDrive\Packages" -enable "True" -Name "Server 2008(R2) x64" -Comments "" -ItemType "folder"
New-Item -Path "$PSDrive\Packages" -enable "True" -Name "Server 2012(R2) x64" -Comments "" -ItemType "folder"

# Create Task Sequence Folders
New-Item -Path "$PSDrive\Task Sequences" -enable "True" -Name "Build" -Comments "" -ItemType "folder"
New-Item -Path "$PSDrive\Task Sequences" -enable "True" -Name "Deploy" -Comments "" -ItemType "folder"

# Create Selection Profiles for Driver Selection
New-Item -Path "$PSDrive\Selection Profiles" -enable "True" -Name "Drivers_WinPE_x64" -Comments "" -Definition "<SelectionProfile><Include path=`"Out-of-Box Drivers\WinPE\x64`" /></SelectionProfile>" -ReadOnly "False"
New-Item -Path "$PSDrive\Selection Profiles" -enable "True" -Name "Drivers_WinPE_x86" -Comments "" -Definition "<SelectionProfile><Include path=`"Out-of-Box Drivers\WinPE\x86`" /></SelectionProfile>" -ReadOnly "False"
New-Item -Path "$PSDrive\Selection Profiles" -enable "True" -Name "Drivers_Virtual_Hyper-V" -Comments "" -Definition "<SelectionProfile><Include path=`"Out-of-Box Drivers\Virtual\Hyper-V`" /></SelectionProfile>" -ReadOnly "False"
New-Item -Path "$PSDrive\Selection Profiles" -enable "True" -Name "Drivers_Virtual_VMware" -Comments "" -Definition "<SelectionProfile><Include path=`"Out-of-Box Drivers\Virtual\VMware`" /></SelectionProfile>" -ReadOnly "False"

# Create Selection Profiles for Packages Selection
New-Item -Path "$PSDrive\Selection Profiles" -enable "True" -Name "Packages_Windows_7_x64" -Comments "" -Definition "<SelectionProfile><Include path=`"Packages\Windows 7 x64`" /></SelectionProfile>" -ReadOnly "False"
New-Item -Path "$PSDrive\Selection Profiles" -enable "True" -Name "Packages_Windows_8.1_x64" -Comments "" -Definition "<SelectionProfile><Include path=`"Packages\Windows 8.1 x64`" /></SelectionProfile>" -ReadOnly "False"
New-Item -Path "$PSDrive\Selection Profiles" -enable "True" -Name "Packages_Server_2008(R2)_x64" -Comments "" -Definition "<SelectionProfile><Include path=`"Packages\Server 2008(R2) x64`" /></SelectionProfile>" -ReadOnly "False"
New-Item -Path "$PSDrive\Selection Profiles" -enable "True" -Name "Packages_Server_2012(R2)_x64" -Comments "" -Definition "<SelectionProfile><Include path=`"Packages\Server 2012(R2) x64`" /></SelectionProfile>" -ReadOnly "False"

Remove-PSDrive ($PSdrive -replace(":",""))

# Get End Time
$endDTM = (Get-Date)

# Echo Time elapsed
"Elapsed Time: $(($endDTM-$startDTM).totalseconds) seconds"

# End of script