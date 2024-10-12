$RDPEnable = 1
$RDPFirewallOpen = 1
$NLAEnable = 0
 
# Enable Remote Desktop Connections
$RDP = Get-WmiObject -Class Win32_TerminalServiceSetting -Namespace root\CIMV2\TerminalServices -Authentication PacketPrivacy
$Result = $RDP.SetAllowTSConnections($RDPEnable,$RDPFirewallOpen)
 
if ($Result.ReturnValue -eq 0)
{
    Write-Host "Remote Connection settings changed sucessfully" -ForegroundColor Cyan
}
else
{
    Write-Host ("Failed to change Remote Connections setting(s), return code "+$Result.ReturnValue) -ForegroundColor Red
    exit
}
 
# Set Network Level Authentication level
$NLA = Get-WmiObject -Class Win32_TSGeneralSetting -Namespace root\CIMV2\TerminalServices -Authentication PacketPrivacy
$NLA.SetUserAuthenticationRequired($NLAEnable) | Out-Null
$NLA = Get-WmiObject -Class Win32_TSGeneralSetting -Namespace root\CIMV2\TerminalServices -Authentication PacketPrivacy
if ($NLA.UserAuthenticationRequired -eq $NLAEnable)
{
    Write-Host "NLA setting changed sucessfully" -ForegroundColor Cyan
}
else
{
    Write-Host "Failed to change NLA setting" -ForegroundColor Red
    exit
}