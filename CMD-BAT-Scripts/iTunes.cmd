@echo off

msiexec.exe ALLUSERS=true reboot=suppress /qn /i "appleapplicationsupport64.msi"
msiexec.exe /qn /norestart /i "applemobiledevicesupport6464.msi"
msiexec.exe /qn /norestart /i "bonjour64.msi"
msiexec.exe /qn /norestart /i "quicktime.msi"
msiexec.exe /qn /norestart /i "itunes6464.msi" 