' VBScript Restart Service.vbs
' Sample script to Stop or Start a Service
' www.computerperformance.co.uk/
' Created by Guy Thomas December 2010 Version 2.4
' -------------------------------------------------------'
Option Explicit
Dim objWMIService, objItem, objService
Dim colListOfServices, strComputer, strService, intSleep
strComputer = "."
intSleep = 15000
'WScript.Echo " Click OK, then wait " & intSleep & " milliseconds"

'On Error Resume Next
' NB strService is case sensitive.
strService = " 'CcmExec' "
Set objWMIService = GetObject("winmgmts:" _
& "{impersonationLevel=impersonate}!\\" _
& strComputer & "\root\cimv2")
Set colListOfServices = objWMIService.ExecQuery _
("Select * from Win32_Service Where Name ="_
& strService & " ")
For Each objService in colListOfServices
objService.StopService()
WSCript.Sleep intSleep
objService.StartService()
Next
'WScript.Echo "Your "& strService & " service has Started"
WScript.Quit
' End of Example WMI script to Start / Stop services

' -------------------------------------------------------'
' Finish Guy Thomas contribution :-)
' -------------------------------------------------------'

' -------------------------------------------------------'
' Start MSDN contribution :-)
' -------------------------------------------------------'

'Set Variables For Actions 
actionNameToRun = "Software Updates Deployment Evaluation Cycle" 
actionNameToRun1 = "Software Updates Scan Cycle"
actionNameToRun2 = "Application Deployment Evaluation Cycle"
actionNameToRun3 = "Discovery Data Collection Cycle"
actionNameToRun4 = "File Collection Cycle"
actionNameToRun5 = "Hardware Inventory Cycle"
actionNameToRun6 = "Machine Policy Retrieval & Evaluation Cycle"
actionNameToRun7 = "Software Inventory Cycle"
actionNameToRun8 = "Software Metering Usage Report Cycle"
actionNameToRun9 = "Software Updates Deployment Evaluation Cycle"
actionNameToRun10 = "User Policy Retrieval & Evaluation Cycle"
actionNameToRun11 = "Windows Installer Source List Update Cycle" 
'Create and use the control panel applet for client actions 
Dim controlPanelAppletManager 
Set controlPanelAppletManager = CreateObject("CPApplet.CPAppletMgr") 
Dim clientActions 
Set clientActions = controlPanelAppletManager.GetClientActions() 
Dim clientAction 
'Find which actions are available 
For Each clientAction In clientActions 
'List available client actions, output using the Name property (below). 
'        wscript.echo "Action: " & clientAction.Name 
'Run statements per results 
        If clientAction.Name = actionNameToRun Then 
                clientAction.PerformAction 
                 
        End If 
         
        If clientAction.Name = actionNameToRun1 Then 
                clientAction.PerformAction 
                 
        End If
        If clientAction.Name = actionNameToRun2 Then 
                clientAction.PerformAction 
                 
        End If
        If clientAction.Name = actionNameToRun3 Then 
                clientAction.PerformAction 
                 
        End If
        If clientAction.Name = actionNameToRun4 Then 
                clientAction.PerformAction 
                 
        End If
        If clientAction.Name = actionNameToRun5 Then 
                clientAction.PerformAction 
                 
        End If
        If clientAction.Name = actionNameToRun6 Then 
                clientAction.PerformAction 
                 
        End If
        If clientAction.Name = actionNameToRun7 Then 
                clientAction.PerformAction 
                 
        End If
        If clientAction.Name = actionNameToRun8 Then 
                clientAction.PerformAction 
                 
        End If
        If clientAction.Name = actionNameToRun9 Then 
                clientAction.PerformAction 
                 
        End If
        If clientAction.Name = actionNameToRun10 Then 
                clientAction.PerformAction 
                 
        End If
        If clientAction.Name = actionNameToRun11 Then 
                clientAction.PerformAction 
                 
        End If
Next