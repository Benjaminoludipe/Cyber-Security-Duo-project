# Checks that extract_ips.ps1 turns netstat endpoints into bare IPs on Windows, macOS and Linux.
# Run: pwsh tests/test_parse.ps1
$src = Get-Content "$PSScriptRoot/../extract_ips.ps1" -Raw
Invoke-Expression ([regex]::Match($src, '(?s)function Get-AddressFromEndpoint \{.*?\n\}').Value)

$cases = [ordered]@{
    '203.0.113.10:443'          = '203.0.113.10'        # Windows / Linux IPv4
    '[2001:db8::10]:443'   = '2001:db8::10'   # Windows IPv6
    '203.0.113.10.443'          = '203.0.113.10'        # macOS IPv4
    '2001:db8::10.443'     = '2001:db8::10'   # macOS IPv6
    '2001:4860:4860::8888:443'  = '2001:4860:4860::8888' # Linux IPv6
}
$fail = 0
foreach ($k in $cases.Keys) {
    $got = Get-AddressFromEndpoint $k
    if ($got -eq $cases[$k]) { "ok    $k -> $got" } else { "FAIL  $k -> $got (expected $($cases[$k]))"; $fail++ }
}

# The remote address must come from the column before ESTABLISHED, whatever the leading spacing
$lines = @(
    '  TCP    10.0.0.5:52000         203.0.113.10:443       ESTABLISHED',          # Windows
    'tcp4       0      0  10.0.0.5.52345         203.0.113.10.443       ESTABLISHED', # macOS
    'tcp        0      0 10.0.0.5:52345          203.0.113.10:443        ESTABLISHED' # Linux
)
foreach ($line in $lines) {
    $p = $line.Trim() -split '\s+'; $i = [array]::IndexOf($p, 'ESTABLISHED')
    $got = Get-AddressFromEndpoint $p[$i - 1]
    if ($got -eq '203.0.113.10') { "ok    line -> $got" } else { "FAIL  line -> $got"; $fail++ }
}
"failures: $fail"
exit $fail
