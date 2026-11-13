param (
    [string]$OutputFile = "remote_ips.csv"
)

# Turns a netstat remote-address field into a bare IP address.
# Windows prints 1.2.3.4:443 (or [::1]:443); macOS prints 1.2.3.4.443;
# Linux prints 1.2.3.4:443 and IPv6 as 2001:db8::1:443 (no brackets)
function Get-AddressFromEndpoint {
    param([string]$Endpoint)

    if ($Endpoint -match '^\[(.+)\]:\d+$') { return $matches[1] }               # [IPv6]:port
    if ($Endpoint -match '^(\d{1,3}(?:\.\d{1,3}){3}):\d+$') { return $matches[1] } # IPv4:port (Windows)
    if ($Endpoint -match '^(\d{1,3}(?:\.\d{1,3}){3})\.\d+$') { return $matches[1] } # IPv4.port (macOS)
    if ($Endpoint -match '^(.+)\.\d+$') { return $matches[1] }                    # IPv6.port (macOS)
    if ($Endpoint -match '^(.*:.*):\d+$') { return $matches[1] }                   # IPv6:port (Linux, no brackets)
    return $Endpoint
}

function Get-RemoteIPs {

    # On macOS, -l prints full IPv6 addresses (they are truncated otherwise).
    # Windows and Linux netstat do not need it (and -l means "listening" on Linux).
    $netstatArgs = if ($IsMacOS) { "-anl" } else { "-an" }

    netstat $netstatArgs |
        Select-String "ESTABLISHED" |
        ForEach-Object {
            # Trim first: Windows lines start with spaces, which made the old split pick the wrong column
            $parts = $_.Line.Trim() -split "\s+"
            $stateIndex = [array]::IndexOf($parts, "ESTABLISHED")
            # The remote address is always the column just before the state
            if ($stateIndex -gt 0) { Get-AddressFromEndpoint $parts[$stateIndex - 1] }
        } |
        Where-Object { $_ } |
        Sort-Object -Unique |
        ForEach-Object {
            [PSCustomObject]@{
                RemoteIP = $_
            }
        }
}

Get-RemoteIPs | Export-Csv $OutputFile -NoTypeInformation
Write-Output "Remote IP list saved to $OutputFile"
