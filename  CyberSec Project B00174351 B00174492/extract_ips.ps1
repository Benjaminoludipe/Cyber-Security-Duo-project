param (
    [string]$OutputFile = "remote_ips.csv"
)

function Get-RemoteIPs {

    netstat -an |
        Select-String "ESTABLISHED" |
        ForEach-Object {
            $parts = $_.Line -split "\s+"
            ($parts[4] -split ":")[0]
        } |
        Sort-Object -Unique |
        ForEach-Object {
            [PSCustomObject]@{
                RemoteIP = $_
            }
        }
}

Get-RemoteIPs | Export-Csv $OutputFile -NoTypeInformation
Write-Output "Remote IP list saved to $OutputFile"
