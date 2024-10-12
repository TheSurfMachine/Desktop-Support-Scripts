<#	
.SYNOPSIS
    Imports a list of computer/server names from a CSV file and attempts to reset the local admin password 
    for each.

.PARAMETER InputFile
    Path for the Input CSV file

.PARAMETER StartTranscript
    Switch to start transcript and store in current directory as text file.

.DESCRIPTION
    Takes an input CSV file with the column 'ComputerName', and 'Status' and attempts to reset the local admin
    password for the local admin account named 'Ammtec'.
        
    Scipt Steps:
    - First it will check if encrypted password text file is present. If not, it will prompt the user to 
      enter a password.
    - It will then Import the master CSV file. For any computers where 'Status' is not 'SUCCESS', it will do:
            : check if the server/computer is contactable using PING
            : attempt to reset local admin password
            : update CSV file 'Status' with 'SUCCESS' or 'PingFAILED' or 'ERROR'
    - Any errors found during PING/password reset are exported into CSV file with 
       'Failed-PING' or 'ERROR' in the Status Column of the master CSV file. 
       For detailed error information, the full error is appended to the Output Error Log.       
    
.INPUTS
    InputFile - Master CSV File with "," delimited attributes. Must include a column with header 
        'ComputerName'
        'Status'

.OUTPUTS
    reset_AdminPassword-Transcript - TXT file contains PowerShell transcript (if StartTranscript is used)
    reset_AdminPassword-Errors.txt - Text file containing ALL runtime errors
  
.NOTES
    Version:        1.0
    Author:         Sidharth Zutshi (IDC S.p.A)
    Creation Date:  11/01/2018
    Change Date:    N/A
    Purpose/Change: N/A

.EXAMPLE
    PS C:\> .\reset_AdminPassword.ps1 -InputFile Master_ComputerList.csv
    
    Runs script for all computers in the input CSV file. Attempts to reset password for all computers with 
    'Status' not as 'SUCCESS' in the master CSV.

.EXAMPLE
    PS C:\> .\reset_AdminPassword.ps1 -InputFile Master_ComputerList.csv -StartTranscript

    Runs script for all computers in the input CSV file and additionally outputs PS transcript. 


#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $True)]
    [ValidateNotNullOrEmpty()]
        [string]$InputFile,        
        [switch]$StartTranscript = $False
    )

$CurrentDate = (Get-Date -Format "dd-MM-yyyy_HH-mm-ss")
$count = 0
$errcount = 0

#region----------------------------------------------[Parameter Declarations]---------------------------------------------------

$OutputTranscript = ".\reset_AdminPassword-Transcript_$CurrentDate.txt"
$OutputErrorLog = ".\reset_AdminPassword-Errors.txt"
$CurrentPreference = $Global:ErrorActionPreference
$Global:ErrorActionPreference = 'Stop'
$CurrentVerbose = $Global:VerbosePreference
$Global:VerbosePreference = 'Continue'

$PasswordFile = ".\encrypted_password.txt"
#endregion


#region--------------------------------------------------[Execution Start]-------------------------------------------------------

if ($StartTranscript -eq $True)
{
    Start-Transcript -Path $OutputTranscript
}

#region: Add Header to Output
Write-Output "`n`n
Starting script ***reset_AdminPassword.ps1*** with parameters set as
------------------------------------------------------
InputFile = $InputFile
StartTranscript = $StartTranscript
Encrypted Password File = $PasswordFile
Output Transcript = $OutputTranscript
------------------------------------------------------" 

$Current = (Get-Date -Format "dd-MM-yyyy_HH:mm:ss")

#endregion

if (Test-Path $PasswordFile)
{
    Write-Verbose "Encrypted Password File already exists!"
    Write-Verbose "The same password will be used..."
    $password = (Get-Content $PasswordFile | ConvertTo-SecureString)
}
else
{
    $password = Read-Host "Enter the new Admin password" -AsSecureString
    $password | ConvertFrom-SecureString | Set-Content $PasswordFile
    Set-ItemProperty -Path $PasswordFile -Name IsReadOnly -Value $true -Force -ErrorAction Stop
}

$pwd1_text = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

#Import CSV file into variable for processing
Write-Verbose "Importing CSV File for list of computer names to process..." 
$Items = (Import-CSV $InputFile -ErrorAction Stop | Select-Object -Property ComputerName,Status) 

#region: Loop to process each computer
foreach($Item in $Items)
{

    $Error.Clear()

    if($Item.Status -ne "SUCCESS")
    {
        Write-Verbose "  | Running Test-Connection for $($Item.ComputerName)..."     
        
        $ComputerName = $Item.ComputerName.toUpper()
        Write-Verbose "        [Test-Connection] $ComputerName" 
        $Ping = (Test-Connection $ComputerName -Count 1 -ErrorAction SilentlyContinue)

        try
        {
            if($Ping)
            {
                Write-Verbose "        Ping SUCCEEDED!"
                Write-Verbose "  | Attempting to reset password for $ComputerName..."
                $account = [ADSI]("WinNT://$ComputerName/Ammtec,user")
		        $account.psbase.invoke("setpassword",$pwd1_text)
		        Write-Verbose "  |   | Password reset completed SUCCESSFULLY!!"
                Write-Verbose ""
                $Item.Status = "SUCCESS"
                $count++
            }
            else
            {
                Write-Verbose "        Ping FAILED!"
                Write-Verbose "  | Continuing with next item on the list..."
                Write-Verbose ""
                $Item.Status = "PingFAILED"
                $errcount++
            }

        }
        catch
        {
            Write-Host "[ERRORCATCH]: Below Error occured during processing for $ComputerName." -ForegroundColor Red
            Write-Host "Error is appended to Error Logs" -ForegroundColor Red
            $Error[0]
            "Error Occured for Computer $ComputerName on $(Get-Date)`n`n" >> $OutputErrorLog
            $Error[0] >> $OutputErrorLog
            "--------------------------------------------------" >> $OutputErrorLog
            $Item.Status = "ERROR"
            $errcount++
        }
    }
    else
    {
        Write-Verbose "  | Skipping $($Item.ComputerName)...    (Status = 'SUCCESS' in Master CSV)"
        Write-Verbose ""
        $count++
    }

}
#endregion

#re-export and overwrite the master CSV file
Write-Verbose "Exporting updated list to Master CSV File..."
$Items | Export-Csv $InputFile -Force -NoTypeInformation
Write-Verbose "File updated!"

$Global:ErrorActionPreference = $CurrentPreference
$Global:VerbosePreference = $CurrentVerbose

if ($StartTranscript -eq $True)
{
    Stop-Transcript
}


#endregion


#region------------------------------------------------[End Processing]-----------------------------------------------------------

#region: Add footer to Output
$CurrentEnd = (Get-Date -Format "dd-MM-yyyy HH:mm:ss")
						 
Write-Output "`n`n`n**************************End Script**************************`n`n" 
Write-Output "Script Ended on $CurrentEnd
Total Items Processed SUCCESSFULLY = $count
Total Items with ERROR = $errcount

"

#endregion

#endregion


#--------------------------------------------------------------***End Script***----------------------------------------------------------
