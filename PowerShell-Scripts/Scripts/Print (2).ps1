#############################################################################
# New-UserAD and Email
# Create email and AD Account for new Users in EUPOL Afghanistan
#
# Rahmatullah Fedayizada
# CIS Assistant
# Mobile: 0796660969
# Email: rahmat.fedayizada@eupol-afg.eu
# ============================================================================

## Put your own print server name

$printserver = "printserver.contoso.local"
Get-WMIObject -class Win32_Printer -computer $printserver | Select Name,DriverName,PortName | Export-CSV -path 'C:\Users\rahmat.fedayizada\Desktop\printers.csv'