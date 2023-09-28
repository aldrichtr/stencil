
$tokens | ForEach-Object {
    $start = $_.STart.Index
    $end = $_.End.Index
    $snip = ( -join ($content[$start..$end]))
    "-- ($start - $end) --"
    "Token:   [$([regex]::Escape($_.Content))]"
    "Content: [$([regex]::Escape($snip))]"
    '--'
}
