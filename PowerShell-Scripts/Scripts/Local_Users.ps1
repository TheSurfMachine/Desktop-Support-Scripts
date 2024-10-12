 $module = Get-Module -Name ActiveDirectory -ListAvailable | Select Name
 if(!$module.Name){
    Write-Host "Module Active Directory is Required" -ForegroundColor Red
 }else{
 
  
 
 $cred = Get-Credential #Read credentials
 $username = $cred.username
 $password = $cred.GetNetworkCredential().password

 # Get current domain using logged-on user's credentials
 $CurrentDomain = "LDAP://" + ([ADSI]"").distinguishedName
 $domain = New-Object System.DirectoryServices.DirectoryEntry($CurrentDomain,$UserName,$Password)
 #Restricted for specific users
 if($cred.UserName -like "*\UserRestrict" -or $cred.UserName -like "*\UserRestrict" ){
    Write-Host "Your access is not allowed for this script, Please Contact your Administrator"

 }
    else{

    #authentication Failed
    if ($domain.name -eq $null)
    {
     write-host "Authentication failed - please verify your username and password."
     exit #terminate the script.
        }
        else
        {
     

cls
$Host.UI.RawUI.BackgroundColor = ($bckgrnd = 'Bkack')
$Host.UI.RawUI.ForegroundColor = 'Green'
$Host.PrivateData.ErrorForegroundColor = 'Red'
$Host.PrivateData.ErrorBackgroundColor = $bckgrnd
$Host.PrivateData.WarningForegroundColor = 'Magenta'
$Host.PrivateData.WarningBackgroundColor = $bckgrnd
$Host.PrivateData.DebugForegroundColor = 'Yellow'
$Host.PrivateData.DebugBackgroundColor = $bckgrnd
$Host.PrivateData.VerboseForegroundColor = 'Green'
$Host.PrivateData.VerboseBackgroundColor = $bckgrnd
$Host.PrivateData.ProgressForegroundColor = 'Cyan'
$Host.PrivateData.ProgressBackgroundColor = $bckgrnd
Clear-Host

#Verify if the module exists, if it does not exist, download it install it and import it
$path = Test-Path -Path 'C:\Program Files\WindowsPowerShell\Modules\localaccount'
if(!$path){
Save-Module -Name localaccount -Path "C:\Program Files\WindowsPowerShell\Modules\localaccount"
Install-Module -Name Pscx -RequiredVersion 1.6
Import-Module -Name localaccount -RequiredVersion 1.6
}else{ Write-Host "Module Already exists, proceed to Import" | Import-Module -Name localaccount -RequiredVersion 1.6}

Do {
cls
Write-Host "
----------MENU Create Local User----------
1 = Change Password Local User
2 = Create Local User
3 = Create Mass Local User
4 = Delete Mass Local User 
5 = Exit
--------------------------" -BackgroundColor Black -ForegroundColor Green
$choice1 = read-host -prompt "Select number & press enter" 
} until ($choice1 -eq "1" -or $choice1 -eq "2" -or $choice1 -eq "3" -or $choice1 -eq "4" -or $choice1 -eq "5")


Switch ($choice1) {
"1" {
        cls
        Write-Host "Reset Password Local User" -BackgroundColor Black -ForegroundColor Green
        $server = Read-Host -Prompt "Enter IP or Hostname Server"
            $usuario = Read-Host -Prompt "Enter User"
            $Password = Read-Host -Prompt "Enter Password" -AsSecureString

            $search = Get-LocalUser -name $usuario -Computername $server | Select Name -ErrorAction SilentlyContinue
            if($search.Name -eq $usuario){
    
                $test = Set-LocalUser -Name $usuario -Password  $Password -Computername $server
        
                $test

                Write-Host "Change Password Successful $usuario" -BackgroundColor Black -ForegroundColor Green
        
    
            }else{

                Write-Host "User Not Exist" -ForegroundColor Red
            }
    }


"2" {
        cls
        $server = Read-Host "Enter Server Name Or IP"
        $usuario = Read-Host "Enter User to Create"
        $Password = Read-Host -Prompt "Enter Password" -AsSecureString 
        $Descrip = Read-Host -Prompt "Enter Description or Ticket for User Account"
        $group = Read-Host -Prompt "Please Enter Group for User Account or Deaful User Group"

        $existe = Get-LocalUser -name $usuario -Computername $server | Select Name -ErrorAction SilentlyContinue
        if($existe -eq $usuario){
            Write-Host "Usuario $usuario ya Existe" -BackgroundColor Black -ForegroundColor Red
            }else{

            New-LocalUser -Name $usuario -Computername $server -Password $Password -Description $Descrip -Verbose
            Add-LocalGroupMember -GroupName $group -name $usuario -Computername $server -Verbose 
            Write-Host "Usuario $usuario Creado " -BackgroundColor Black -ForegroundColor Green
    
            }

}




"3" {
        cls
        $user_net = $cred.UserName
        Write-Host "verify that the file server.txt content is in the same directory as the script " -BackgroundColor Black -ForegroundColor Gray
        $usuario = Read-Host "Please Enter User Account"
        $Password = Read-Host -Prompt "Enter Password" -AsSecureString
        $Group = Read-Host -Prompt "Please Enter User Group"
        $des = "Local Administrator Create For "
        foreach($server in Get-Content $PSScriptRoot\server.txt){
                     
            New-LocalUser -Name $usuario -Computername $server -Description $des -Password $Password -Verbose
            Add-LocalGroupMember -GroupName $Group -name $usuario -Computername $server -Verbose -ErrorAction SilentlyContinue
            Write-Host "Usuario $usuario Creado " -BackgroundColor Black -ForegroundColor Green
            $result = Get-LocalUser -name $usuario -Computername $server | Select Name
            if($result.Name -eq $usuario){
               Write-Output "User $usuario Create For $user_net In Server $server" | Out-File -FilePath E:\users\creation_user.txt -Append
                
            }else{
            
                Write-Output "User $usuario Not Createsd In $server" | Out-File -FilePath E:\users\creation_user.txt -Append
            
            }
              
        }
        
    }
    

"4" {
        
        cls
        $user_net = $cred.UserName
        Write-Host "verify that the file server.txt content is in the same directory as the script " -BackgroundColor Black -ForegroundColor Gray
        $usuario = Read-Host "Please Enter User Account"
        foreach($server in Get-Content $PSScriptRoot\server.txt){
           Remove-LocalUser -Name $usuario -Computername $server -Verbose
            Write-Output "User $usuario Delet For $user_net In Server $server" | Out-File -FilePath E:\users\Usuario_eliminado.txt -Append
                
        }

    }

    "5" {

        Return # Exit Script

        }
    }
  }
 }
}