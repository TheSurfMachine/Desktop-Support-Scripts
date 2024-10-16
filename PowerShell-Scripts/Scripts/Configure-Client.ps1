
[cmdletbinding()]
param(
    $DomainAdminUser,
    $DomainAdminDomain,
    $DomainAdminPassword,
    $OfficeURI = 'https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_11901-20022.exe',
    $siteCode = 'CHQ'
    )

Start-Transcript

#region Setup for reboot


Function Get-ShellFolderPath {
    param (
        [GUID] $GUID
    )

    # REquired for Win 7 Compat

    $type = Add-Type @"
using System;
using System.Runtime.InteropServices;

public class shell32
{
    [DllImport("shell32.dll")]
    private static extern int SHGetKnownFolderPath(
            [MarshalAs(UnmanagedType.LPStruct)] 
            Guid rfid,
            uint dwFlags,
            IntPtr hToken,
            out IntPtr pszPath
        );

        public static string GetKnownFolderPath(Guid rfid)
        {
        IntPtr pszPath;
        if (SHGetKnownFolderPath(rfid, 0, IntPtr.Zero, out pszPath) != 0)
            return ""; // add whatever error handling you fancy
        string path = Marshal.PtrToStringUni(pszPath);
        Marshal.FreeCoTaskMem(pszPath);
        return path;
        }
}
"@

    [shell32]::GetKnownFolderPath($Guid) | Write-Output

}


$oShell = new-object -ComObject WScript.Shell
$RestartLink = join-path ( Get-ShellFolderPath '{82A5EA35-D9CD-47C5-9629-E15D2F714E6E}' ) "RebuildPC.lnk"

if ( -not ( test-path $RestartLink ) ) { 
    $oLink = $oShell.createShortCut( $RestartLink )
    $oLink.TargetPath = 'powershell.exe'
    $oLink.ARguments = "-ExecutionPolicy Bypass -command ""c:\windows\panther\Configure-Client.ps1 -DomainAdminUser $DomainAdminUser -DomainAdminDomain $DomainAdminDomain -DomainAdminPassword $DomainAdminPassword; write-host 'Press any key to continue...'; read-host"""
    $oLink.Save()
}

#endregion

#region Rename Computer and join domain
###########################################################################

$NewComputerName = get-itemProperty 'hklm:\Software\Microsoft\Virtual Machine\Guest\Parameters' | % { $_.VirtualMachineName -split '-' } | Select -last 1

$comp = gwmi Win32_ComputerSystem

if ( $Comp.Name -ne $NewComputerName ) {

    write-host "rename computer to $NewComputerName"
    $comp.rename($NewComputerName,$DomainAdminPassword,$DomainAdminUser)
    shutdown -r -f -t 0
    return
}

if ( ($NewComputerName -ne 'Client3') -and ($NewComputerName -ne 'Client4' ) ) {
    if ( gwmi win32_computersystem | where-object { $_.partofdomain -ne $true } ) {
        write-host "Join Domain $DomainAdminDomain $DomainAdminUser"
        $result = $comp.JoinDomainOrWorkGroup($DomainAdminDomain, $DomainAdminPassword, $DomainAdminUser, $null , 23)
        $result | out-string | write-host
        $result.ReturnValue | Write-Host
        if ( $result.ReturnValue -eq 0 ) {
            write-host "Reboot successfull $($result.returnValue)"
            shutdown -r -f -t 0
            return
        }
        else {
            clear-host 
            ipconfig 
            write-host ("#" * 80)
            write-host "Unable to join machine to domain [$DomainAdminDomain]. Error $Result"
            write-host "   ....  Possible network issue? Wait 5 minutes, reboot and retry... "
            start-sleep -Seconds ( 60 * 5 ) 
            shutdown -r -f -t 0
            return
        }
    }
}


#endregion

#region configuration Tasks
###########################################################################

if ( ($NewComputerName -ne 'Client3') -and ($NewComputerName -ne 'Client4' ) ) {

    write-host "Base CFG Tasks"
    if ( GWMI Win32_OperatingSystem | where-object { $_.ProductType -ne 1 } ) {

        write-host "Ensure that WinRM is enabled"
        & WinRM quickconfig -quiet -force

        Enable-PSRemoting -force -ErrorAction SilentlyContinue
    }
    netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes

    if ( test-path "\\cm1\sms_$($SiteCode)\StagingClient\CCMSetup.exe" -ErrorAction SilentlyContinue ) {
        write-host "Installing CMCLient [$($SiteCode)] [$([DateTime]::now.TOString('s'))]"
        & \\cm1\sms_$($SiteCode)\StagingClient\CCMSetup.exe /mp:cm1 /LOGON /ForceReboot SMSSITECODE=$SiteCode | out-null
        write-host "Finished CMCLient [$($SiteCode)] [$([DateTime]::now.TOString('s'))]"
    }

}

#endregion

#region Office 365 installation
###########################################################################

if ( $NewComputerName -eq 'Client7' ) {

    write-host "Windows 7 installation"

    $SourceFilePath = "$env:temp\office\setup.exe"
    if ( -not ( test-path $SourceFilePath ) ) {
        $local = "$env:TEMP\OfficeSetup.exe"

        (New-Object System.Net.WebClient).DownloadFile($OfficeURI, $local)
        if ( -not ( test-path $Local ) ) {
            throw "Missing office365 $Local"
        }

        & $env:TEMP\OfficeSetup.exe /extract:$env:temp\office /log:$env:temp\officeInstall.log /quiet /norestart | out-null
        start-sleep 10

        $SourceFilePath = "$env:temp\office\setup.exe"
        if ( -not ( test-path $SourceFilePath ) ) { throw "missing Office\Setup.exe" }
       
    }

    '<Configuration><Add OfficeClientEdition="32" Channel="InsiderFast" ><Product ID="O365ProPlusRetail"><Language ID="en-us" /></Product></Add>' | out-file $env:temp\Office365ProPlus.xml -Append
    '<Updates Enabled="TRUE" /><Display Level="None" AcceptEULA="TRUE" /><Logging Path="%temp%" /></Configuration>' | out-file $env:temp\Office365ProPlus.xml -Append

    write-host "Launch Office365"
    & $SourceFilePath /configure $env:temp\Office365ProPlus.xml
    write-host "Finished Office365"

}


#endregion

#region Reboot

write-host "Cleanup"

set-ItemProperty 'HKLM:\software\Microsoft\Windows NT\CurrentVersion\Winlogon' -name 'AutoAdminLogon' -Value 0 -EA SilentlyContinue
set-ItemProperty 'HKLM:\software\Microsoft\Windows NT\CurrentVersion\Winlogon' -name 'DefaultUserName' -Value 'LabAdmin' -EA SilentlyContinue
set-ItemProperty 'HKLM:\software\Microsoft\Windows NT\CurrentVersion\Winlogon' -name 'DefaultDomainName' -Value 'Corp' -EA SilentlyContinue
remove-item $RestartLink

& shutdown.exe -s -t 30

#endregion

