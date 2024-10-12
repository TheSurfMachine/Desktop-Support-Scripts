<#===================================================================================================================  
Script Name    : copytomultilocation.ps1  
Purpose    : To copy data to multiple location  
Author        : Pradeep Raju - 8015648323  
Date Created    : 10/5/2017  
  
=====================================================================================================================#> 

$source= Read-host "Enter the path with filename to be copied"
$path=Read-host "Enter the path for file with multiple destination server details"
$mdestinations= get-content $path
foreach($mdestination in $mdestinations)
{
copy $source $mdestination
}
