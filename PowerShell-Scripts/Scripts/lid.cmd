@echo off
set debug=1
::*************************
:: Script Name: lid.cmd
:: author: Stephen D Arsenault
:: Creation Date: 2013-september-07
:: Modified Date: 2013-september-07
:: Description:	Changes the lid action to sleep or do nothing
:: parameters: 	- on: sets lid action to do nothing
::		- off: sets lid action to sleep
::*************************

echo Getting current scheme GUID
::store the output of powercfg /getactivescheme in %cfg%
for /f "tokens=* USEBACKQ" %%a in (`powercfg /getactivescheme`) do @set cfg=%%a
if %debug%==1 echo Current %cfg%

::trim power config output to get GUID
set trimcfg=%cfg:~19,36%
if %debug%==1 echo %trimcfg%

::accepts arguments
if %1==off set newVal=001
if %1==OFF set newVal=001
if %1==on set newVal=000
if %1==ON set newVal=000

::make power scheme change
powercfg /setdcvalueindex %trimcfg% 4f971e89-eebd-4455-a8de-9e59040e7347 5ca83367-6e45-459f-a27b-476b1d01c936 %newVal% >nul 2>&1

powercfg /setacvalueindex %trimcfg% 4f971e89-eebd-4455-a8de-9e59040e7347 5ca83367-6e45-459f-a27b-476b1d01c936 %newVal% >nul 2>&1

if %errorlevel%==1 echo "Invalid Parameters"
if %errorlevel%==1 pause
if %errorlevel%==1 echo %date% %time% Invalid Parameters: %1 >>C:\tools\lid.log
echo %date% %time% %1 >>C:\tools\lid.log

::apply changes
powercfg /s %trimcfg%