<# 
   .Synopsis 
    This script will use the Sysinternals PsLoggedon.exe tool to get the list of users logged onto a workstation or computer
    
   .Description 
    The script has a check built in to validate that the computer name belongs to your domain. It will also get the full name of the logged on user back in the results.
    
    There is a built in check to ask the operator if they would like to rerun the script.
    
    The script can be used with the parameter PathToPSLoggedon to specify the location of PsLoggedon.exe. Or this can be set to always default to this location.
    
    The script is built upon the original by Glenn Sizemore detailed at http://goo.gl/21qFZ
    
   .Parameter PathToPSLoggedon
    Alter the location of the path to PsLoggedon.exe
    
   .Example 
    PS C:> .\Get-LoggedOnUsers.ps1 -PathToPSLoggedon "\\server\share\_Tools\PSTools\"

    Enter the name of computer or server to check: PC1
    .....

    User(s) logged onto PC1

    Domain     User
    ------     ----
    POWERSERVE Joe Bloggs
    .....

   .Notes
    
    NAME: Get-LoggedOnUsers
    AUTHOR: jdunlop 
    LASTEDIT: Thursday, 8 September 2011
    KEYWORDS: 

#Requires -Version 2.0 
#> 

Param(
    [Parameter()]
    [String]$PathToPSLoggedon #= "\\server\share\_Tools\PSTools\"
)

$Searcher = New-Object DirectoryServices.DirectorySearcher([ADSI]"")

While ($choice -ne 1)
{

    Clear-Host
    
    While ($account -ne "")
    {
        $Computer = Read-Host "Enter the name of computer to check for logged on users" 
        
        Clear-Host
        
        $Searcher.filter = "(&(objectCategory=Computer)(cn=$Computer))"
        $account = $searcher.findone()
        
        If ($account) {break}
        
        Write-Warning "No computer account exists for $(($Computer).ToUpper()) in the Domain."
        
    } # End While
       
    $Results = $null
    [object[]]$Results = Invoke-Expression ($PathToPSLoggedon + "PsLoggedon.exe -accepteula -x -l \\$Computer  2> null") | 
        Where-Object {$_ -match '^\s{2,}((?<domain>\w+)\\(?<user>\S+))'} |
        Select-Object @{ 
            Name = 'Domain' 
            Expression = {$matches.Domain} 
        }, # End Expression
        @{ 
            Name = 'User' 
            Expression = {
            
                $Searcher.filter = "(&(objectcategory=person)(objectclass=user)(SAMAccountName=$($matches.user)))"
                ($searcher.findone()).properties.displayname
                    
            }  # End Expression
        } # End hash table

    "User(s) logged onto $(($Computer).ToUpper())"

    $Results | Format-Table -auto

    $title = 'Would you like to rerun?'
    $rerun = New-Object System.Management.Automation.Host.ChoiceDescription '&Rerun','Rerun the script'
    $exit = New-Object System.Management.Automation.Host.ChoiceDescription '&Exit','Aborts the script'
    $options = [System.Management.Automation.Host.ChoiceDescription[]] ($rerun,$exit)
 
    $choice = $host.ui.PromptForChoice($title,$null,$options,1)
    
} # End While

