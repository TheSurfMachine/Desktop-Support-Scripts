
#------------------------------------------------------------------------------------
#Author : Madhu Sunke
#Script will Fetch and reset the local admin password by using LAPS PS module
#Date : 7/19/2016
#------------------------------------------------------------------------------------

#Function Will fetch the Edadmin Password , will use the Get-AdmPwdPassword cmdlet
Function Get-EdadminPassword
{
 [cmdletbinding()]
    Param(
    [Parameter(Mandatory=$true,HelpMessage="Enther the Computer Name or HostName or IP Address ")]
     
    [String]$ComputerName
    
    )

    begin 
    {

    Write-Verbose " Started Script at $(get-date) to fetch the EDAdmin Password"
    

    }
    process
    {

    if (Test-Path -Path C:\WINDOWS\System32\WindowsPowerShell\v1.0\Modules\AdmPwd.PS)
    {
    Write-Verbose " Contacting AD to retrieve the EDAdmin Password for $($ComputerName)"
    try
    {
    $pwd = Get-AdmPwdPassword -ComputerName $ComputerName -ErrorAction Stop

    if($pwd.Password)
    {

    $Found = 1
    
    Write-Verbose " Successfully fetched the EDAdmin password" 

    $date = (Get-Date).tostring("MMddyyyy")

    "EDAdmin Password for $($ComputerName) is  $($pwd.Password) and expires at $($pwd.ExpirationTimestamp) " | Out-File $env:SystemDrive\EdadminPassword.log -Append
    
    }
    else
    {

    Write-Warning " Check whether you have access to fetch the EDAdmin Passowrd with your Current Credentials or Enter the valid HostName....!!"

    }
    }

catch
{

Write-Warning " Error occured:: $_.Exception.Message"
Write-Warning " Please check LAPS MSI Installation , Please re-install the MSI with All features to access PS Cmdlets...! or Move the machine to Appropriate OU and run gpupdate /force"

}

    }

    else
    {
    
     Write-Warning " Unable to fetch the Module to manage the LAPS, please Re-install the MSI with all the features"

    $choice = Read-Host "Select [1] - Re-Install the LAPS MSI , [2]- exit from the script"

switch ($choice)

{ 
  

  1 {  $RValue = Reinstall-LAPSMSI
  
  if ($RValue -eq  0)
  {
  
  Write-Verbose "Successfully reinstalled the LAPS MSI, Please Re-run the Script to get EDAdmin Password"
  
  }

  elseif ($RValue -eq -1)
  {
  
  Write-Verbose "Failed During the LAPS reinstall, please Reboot and try again"
  }
  else
  {

  Write-Warning " LAPS product Not found ; Please Install the Complete package EDxPostInstall share or Contact SCCM Team to get the updated Package...!" 
  
  }

   }

  2 { Write-Warning " Existing form the script.... Please wait!"
  Start-Sleep 5
  break}

  default {"Wrong Choice"}

}


    }

    }
    end
    {
    if ($Found -eq 1)

    {
    Write-Verbose " Successfully processed and fetched the EDAdmin password for $($ComputerName)"
    Write-Verbose " Please open the EdadminPassword.log from RootDrive to get the Edadmin Password "
    }
    else
    {
    Write-Warning " ERROR::Failed during the cmdlet Execution, Please review the Verbose output and re-run the script again!" 
    
    }
    
    }
}


#Function Will reset the Edadmin Password , will use the Reset-AdmPwdPassword cmdlet
Function Reset-EdadminPassword
{
 [cmdletbinding()]
    Param(
    [Parameter(Mandatory=$true,HelpMessage="Enther the Computer Name or HostName or IP Address ")]
     
    [String]$ComputerName,
    [Parameter(Mandatory=$true,HelpMessage="Enter the date Format in a mm/dd/yyyy")]
    [String]$Effectivedate
    )

    begin 
    {
    Write-Verbose " Started Script at $(get-date) to reset the EDAdmin Password"
    }
    process
    {

    if (Test-Path -Path C:\WINDOWS\System32\WindowsPowerShell\v1.0\Modules\AdmPwd.PS)
    {
    Write-Verbose " Contacting AD to reset the EDAdmin Password for $($ComputerName)"
    try
    {
    $pwd = Reset-AdmPwdPassword -ComputerName $ComputerName -WhenEffective $Effectivedate -ErrorAction Stop 

    if($pwd.Status -match 'PasswordReset')
    {

    $Found = 1
    
    Write-Verbose " Successfully reset the EDAdmin password for $($ComputerName) " 

    "RESET::Successfully reset the EDAdmin password for $($ComputerName) " | Out-File $env:SystemDrive\EdadminPassword.log -Append
    
    }
    else
    {

    Write-Warning " Check whether you have access to reset the EDAdmin Passowrd with your Current Credentials or Enter the valid HostName....!!"

    }
    }

catch
{

Write-Warning " Error occured:: $_.Exception.Message"
Write-Warning " Please check LAPS MSI Installation , Please re-install the MSI with All features to access PS Cmdlets...! or Move the machine to Appropriate OU and run gpupdate /force"

}

    }

    else
    {
    
     Write-Warning " Unable to fetch the Module to manage the LAPS, please Re-install the MSI with all the features"

    $choice = Read-Host "Select [1] - Re-Install the LAPS MSI , [2]- exit from the script"

switch ($choice)

{ 
  

  1 {  $RValue = Reinstall-LAPSMSI
  
  if ($RValue -eq  0)
  {
  
  Write-Verbose "Successfully reinstalled the LAPS MSI, Please Re-run the Script to get EDAdmin Password"

  

  
  }

  elseif ($RValue -eq -1)
  {
  
  Write-Verbose "Failed During the LAPS reinstall, please Reboot and try again"
  }
  else
  {

  Write-Warning " LAPS product Not found ; Please Install the Complete package EDxPostInstall share or Contact SCCM Team to get the updated Package...!" 
  
  }

   }

  2 {Write-Warning " Existing form the script.... Please wait!"
  Start-Sleep 5
  break}

  default {"Wrong Choice"}

}


    }

    }
    
    end
    {

    if ($Found -eq 1)

    {
    Write-Verbose " Successfully processed and reset the EDAdmin password for $($ComputerName)"
    Write-Verbose " Please open the EdadminPassword.log from RootDrive to see the Edadmin Password and ExpirationTime stamp...!"
    }
    else
    {
    Write-Warning " ERROR::Failed during the cmdlet Execution, Please review the Verbose output and re-run the script again!" 
    
    }
    }
}

#function will re-install the MSI to get PS module and LAPS UI
function Reinstall-LAPSMSI 
    
    {

    [cmdletbinding()]
    Param()


    $LAPS =  Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall| Get-ItemProperty | Where-Object {$_.DisplayName -like '*Local Administrator Password Solution*' } 

    if($LAPS)
    {

    $UninstallKey =  $LAPS.PSChildName

     Write-Verbose "LAPS found under the HKLM hive"

     $arguments = @(

    "/i"

    "`"$UninstallKey`""

    "/qb!-"

    "ADDLOCAL=CSE,Management.UI,Management,Management.PS,Management.ADMX ACTION=INSTALL"

)

$process = Start-Process -FilePath msiexec.exe -ArgumentList $arguments -Wait -PassThru


if ($process.ExitCode -eq 0){

    #Write-Verbose "$($LAPS.DisplayName) has been successfully installed" 

    return 0

}

else {

    #Write-Verbose "installer exit code  $($process.ExitCode) for file  $($LAPS.DisplayName)"

    return -1
}

    
    }
    else
    {
    
    #Write-host "Unable to fetch the MSi information , Please check whether LAPS installed or not...."

    return $false
    
    }



}


#Main Function
Function Perform-LAPSoperations
{
 [cmdletbinding()]
    Param(    )

begin {

write-verbose "-----------------------------------------------------"
write-verbose "script started at $(Get-Date)"
write-verbose "-----------------------------------------------------"
}

process
{
$Mainchoice = Read-Host "Select any of the Operation [1]Get-EDAdminPassword [2]Reset-EDAdminPassword [3]Exit"

switch ($Mainchoice)

{ 
  

  1 {Get-EdadminPassword}

  2 {Reset-EdadminPassword}

  3 {Write-Warning " Existing form the script.... Please wait!"
  Start-Sleep 5
  break}

  default { write-warning "Wrong Choice"}

}
}

end
{
write-verbose "-----------------------------------------------------"
write-verbose "script Ended at $(Get-Date)"
write-verbose "-----------------------------------------------------"

}


}

#calling Main function while executing the script
Perform-LAPSoperations -Verbose    