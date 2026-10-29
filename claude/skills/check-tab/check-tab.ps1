param(
    [int[]]$Pane,
    [int]$Lines = 60
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

if (-not $env:ZELLIJ_PANE_ID) {
    throw 'Not running inside zellij: ZELLIJ_PANE_ID is not set.'
}

$myId = [int]$env:ZELLIJ_PANE_ID
$all = zellij action list-panes -a -j | ConvertFrom-Json
$me = $all | Where-Object { -not $_.is_plugin -and $_.id -eq $myId }
if (-not $me) {
    throw "terminal_$myId is not in the pane list."
}

$mates = $all | Where-Object { -not $_.is_plugin -and $_.tab_id -eq $me.tab_id -and $_.id -ne $myId }
if ($Pane) {
    $mates = $mates | Where-Object { $_.id -in $Pane }
}

"Tab '$($me.tab_name)' (id $($me.tab_id)), you are terminal_$myId. $(@($mates).Count) other terminal pane(s) shown."

foreach ($p in $mates) {
    $state = if ($p.exited) { ' [exited]' } elseif ($p.is_focused) { ' [focused]' } else { '' }
    ''
    "=== terminal_$($p.id)$state | title: $($p.title) | command: $($p.terminal_command) ==="
    $screen = zellij action dump-screen --pane-id "terminal_$($p.id)" | Out-String
    $rows = $screen -split "`r?`n"
    $last = ($rows.Count - 1)
    while ($last -ge 0 -and [string]::IsNullOrWhiteSpace($rows[$last])) { $last-- }
    $first = [Math]::Max(0, $last - $Lines + 1)
    if ($last -ge 0) { $rows[$first..$last] }
}
