

# supress error messages
$erroractionpreference = "SilentlyContinue"

# declear border settings
$xlAutomatic=-4105
$xlBottom = -4107
$xlCenter = -4108
$xlContext = -5002
$xlContinuous=1
$xlDiagonalDown=5
$xlDiagonalUp=6
$xlEdgeBottom=9
$xlEdgeLeft=7
$xlEdgeRight=10
$xlEdgeTop=8
$xlInsideHorizontal=12
$xlInsideVertical=11
$xlNone=-4142
$xlThin=2
$xlMedium = -4138
$xlThick = 4

# Open new instance of excel as user running script 
$a = New-Object -comobject Excel.Application
$a.visible = $True 

# create new work book and add worksheet 
$b = $a.Workbooks.Add()
$c = $b.Worksheets.Item(1)
$c.name = "Multi-Ping.ps1" 

# Build Header row
$c.Cells.Item(1,1) = "Querry Name"
$c.Cells.Item(1,2) = "Ping Status"
$c.cells.item(1,3) = "Logged on Account"
$c.cells.item(1,4) = "First Name"
$c.cells.item(1,5) = "Last Name"
$c.cells.item(1,6) = "Phone Number"
$c.cells.item(1,7) = "E-mail Address"
$c.cells.item(1,8) = "Computer Name"
$c.cells.item(1,9) = "IP Address"
$c.cells.item(1,10) = "Computer OU"

# format header row  
$d = $c.UsedRange
$d.Interior.ColorIndex = 19
$d.Font.ColorIndex = 11
$d.Font.Bold = $True
$d.Interior.ColorIndex = 1
$d.Interior.Pattern = 1 
$d.Font.ColorIndex = 2 
$d.HorizontalAlignment = &hFFFFEFDD 
$d.EntireColumn.AutoFit($True)
$d.EntireColumn.AutoFit()

# set INTROW var to 1st row in table
$intRow = 2

# Get list file and dump to array 
$colComputers = get-content MachineList.txt

# Main loop
foreach ($strComputer in $colComputers)
{


$c.Cells.Item($intRow, 1) = $strComputer.ToUpper()
$ping = new-object System.Net.NetworkInformation.Ping
$Reply = $ping.send($strComputer)

if ($Reply.status –eq “Success”) 
{

# get User name useing Wmi
$CS = Gwmi Win32_ComputerSystem -Comp $strComputer -ErrorAction SilentlyContinue

# get IP address of primary network adapter useing Wmi
$NS = Gwmi -Class win32_NetworkAdapterConfiguration -computername $strComputer `
-Filter "IPEnabled='TRUE'" -ErrorAction SilentlyContinue

# set row green on Success and set col 2 to text to "online" 
$c.Cells.Item($intRow, 1).Interior.ColorIndex = 4
$c.Cells.Item($intRow, 2).Interior.ColorIndex = 4
$c.Cells.Item($intRow, 2) = “Online”
$c.Cells.Item($intRow, 3).Interior.ColorIndex = 4
$c.Cells.Item($intRow, 4).Interior.ColorIndex = 4
$c.Cells.Item($intRow, 5).Interior.ColorIndex = 4
$c.Cells.Item($intRow, 6).Interior.ColorIndex = 4
$c.Cells.Item($intRow, 7).Interior.ColorIndex = 4
$c.Cells.Item($intRow, 8).Interior.ColorIndex = 4
$c.Cells.Item($intRow, 9).Interior.ColorIndex = 4
$c.Cells.Item($intRow,10).Interior.ColorIndex = 4


# evaluate user name
if ($CS.UserName -ne $null)
{
# split var into array to remove short domain 
$e = $CS.UserName.Split('\')
$c.Cells.Item($intRow, 3) = $e[1]
$f = $e[1]

# build AD query strings and load user props 
ForEach-Object { 
$dn =  "dc="+$env:USERDNSDOMAIN.replace(".",",dc=") 
  $ObjFilter = "(&(objectclass=User)(sAMAccountName=$f))" 
  $objSearch = New-Object System.DirectoryServices.DirectorySearcher 
  $objSearch.PageSize = 15000 
  $objSearch.Filter = $ObjFilter 
  $objSearch.SearchRoot = "LDAP://$dn" 
  $objsearch.propertiestoload.addrange(@("givenname"))
  $objsearch.propertiestoload.addrange(@("sn"))
  $objsearch.propertiestoload.addrange(@("mail"))
  $objsearch.propertiestoload.addrange(@("telephoneNumber"))
  $AllObj = $objSearch.FindAll() 

# Convert data in $allobj to string from .net data for insert to excel
foreach ($Obj in $AllObj) 
      { $objItemS = $Obj.Properties 
           [string] $e1 = $objItemS.givenname 
           [string] $e2 = $objItemS.sn
		   [string] $e3 = $objItemS.telephonenumber
           [string] $e4 = $objItemS.mail
       }   
       
# insert user data to excel
             $c.Cells.Item($intRow, 4) = $e1
             $c.Cells.Item($intRow, 5) = $e2
             $c.Cells.Item($intRow, 6) = $e3
             $c.Cells.Item($intRow, 7) = $e4 
}     
$d.EntireColumn.AutoFit()
}
else
{

# query Computer last logged on from registry if avaiable for remote registry 
 $ObjReg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computer)  
            $ObjRegKey = $ObjReg.OpenSubKey("SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon")  
            $UserName = $ObjRegKey.GetValue("DefaultUserName") 
if ($UserName -ne $null)
{
$c.Cells.Item($intRow, 3) = $UserName
}
else
{            
$c.Cells.Item($intRow, 3) = "No User Logged On"
$c.Cells.Item($intRow, 4) = "N/A"
$c.Cells.Item($intRow, 5) = "N/A"
$c.Cells.Item($intRow, 6) = "N/A"
$c.Cells.Item($intRow, 7) = "N/A"
}
}

# if col 3 is eq to your username change to no logged on user
if ($c.Cells.Item($intRow, 3).value2 -eq $env:username)
{
$c.Cells.Item($intRow, 3) = "No User Logged On"
$c.Cells.Item($intRow, 4) = "N/A"
$c.Cells.Item($intRow, 5) = "N/A"
$c.Cells.Item($intRow, 6) = "N/A"
$c.Cells.Item($intRow, 7) = "N/A"
}

# evaluate Ip address 
if ($NS.IPAddress[0].startswith("143.158.") -eq $true )
{
$c.Cells.Item($intRow, 9) = $NS.IPAddress[0]
$d.EntireColumn.AutoFit()
}
else
{
$c.Cells.Item($intRow, 9).Interior.ColorIndex = 3
$c.Cells.Item($intRow, 9) = "Failed Resolve IP"
$d.EntireColumn.AutoFit()
}
#parse computer name from WMI data 
if ($CS.Name -ne $null)
{
$c.Cells.Item($intRow, 8) = $CS.Name
$g = $CS.Name
$d.EntireColumn.AutoFit()

#query AD for computers OU 
ForEach-Object { 
$dn =  "DC="+$env:USERDNSDOMAIN.replace(".",",DC=") 
  $ObjFilter = "(&(objectclass=computer)(cn=$g))" 
  $objSearch1 = New-Object System.DirectoryServices.DirectorySearcher 
  $objSearch1.PageSize = 15000 
  $objSearch1.Filter = $ObjFilter 
  $objSearch1.SearchRoot = "LDAP://$dn" 
  $objsearch1.propertiestoload.addrange(@("distinguishedname"))
  $AllObj1 = $objSearch1.FindAll() 

# Convert DN to string from .net data 
foreach ($Obj1 in $AllObj1) 
      { $objItemS1 = $Obj1.Properties 
 [string] $g1 = $objItemS1.distinguishedname

       } 

 # remove unneeded data from DN for input to excel       
$dn2 = $dn.ToLower()
$dn2 = $dn2.Replace("dc=","")
$g1 = $g1.Replace("OU=","/")
$g1 = $g1.Replace("DC=",".")
$g1 = $g1.Replace(",","")
$g1 = $g1.Replace($dn2,"")
$g1 = $g1.Replace("CN=","")
$g1 = $g1.Replace($g,"")
$g1 = $g1.Replace(".gunter.afmc.ds.af.mil","/")
$g1 = $g1.trimstart("/")
$c.Cells.Item($intRow, 10) = $g1
}	
}
else
{
$c.Cells.Item($intRow, 8).Interior.ColorIndex = 3
$c.Cells.Item($intRow, 8) = "Failed to Resolve Name"
$c.Cells.Item($intRow, 9).Interior.ColorIndex = 3
$c.Cells.Item($intRow, 9) = "Failed to Resolve IP"
$c.Cells.Item($intRow,10).Interior.ColorIndex = 3
$c.Cells.Item($intRow,10) = "N/A"
$d.EntireColumn.AutoFit()
}

}
else
{
$c.Cells.Item($intRow, 1).Interior.ColorIndex = 3
$c.Cells.Item($intRow, 2).Interior.ColorIndex = 3
$c.Cells.Item($intRow, 2) = "Offline"
$c.Cells.Item($intRow, 3).Interior.ColorIndex = 3
$c.Cells.Item($intRow, 3) = "N/A"
$c.Cells.Item($intRow, 4).Interior.ColorIndex = 3
$c.Cells.Item($intRow, 4) = "N/A"
$c.Cells.Item($intRow, 5).Interior.ColorIndex = 3
$c.Cells.Item($intRow, 5) = "N/A"
$c.Cells.Item($intRow, 6).Interior.ColorIndex = 3
$c.Cells.Item($intRow, 6) = "N/A"
$c.Cells.Item($intRow, 7).Interior.ColorIndex = 3
$c.Cells.Item($intRow, 7) = "N/A"
$c.Cells.Item($intRow, 8).Interior.ColorIndex = 3
$c.Cells.Item($intRow, 8) = "N/A"
$c.Cells.Item($intRow, 9).Interior.ColorIndex = 3
$c.Cells.Item($intRow, 9) = "N/A"
$c.Cells.Item($intRow,10).Interior.ColorIndex = 3
$c.Cells.Item($intRow,10) = "N/A"
$d.EntireColumn.AutoFit()
}
$Reply = ""


$intRow = $intRow + 1

}

# auto fit cells
$d.EntireColumn.AutoFit()
# set used range 
$d = $c.UsedRange

#apply borders
$d.Borders.Item($xlEdgeLeft).LineStyle = $xlContinuous
$d.Borders.Item($xlEdgeLeft).ColorIndex = $xlAutomatic
$d.Borders.Item($xlEdgeLeft).Color = 1
$d.Borders.Item($xlEdgeLeft).Weight = $xlMedium
$d.Borders.Item($xlEdgeTop).LineStyle = $xlContinuous
$d.Borders.Item($xlEdgeBottom).LineStyle = $xlContinuous
$d.Borders.Item($xlEdgeRight).LineStyle = $xlContinuous
$d.Borders.Item($xlInsideVertical).LineStyle = $xlContinuous
$d.Borders.Item($xlInsideHorizontal).LineStyle = $xlContinuous
$d.BorderAround(1,4,1)

# create table
$c.Listobjects.add().name = "table1"

# apply table style
$c.ListObjects("Table1").TableStyle = "TableStyleMedium1" 

# save file 
$b.SaveAs("Multi-Ping.xlsx")