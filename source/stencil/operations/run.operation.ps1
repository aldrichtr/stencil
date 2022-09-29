Register-StencilOperation 'run' {
    param($params)
    Write-Debug "  Running script:`n$('-' * 80)`n$($params.shell)`n$('-' * 80)"
    $script = [scriptblock]::create($params.shell)
    $script.invoke()
} -Description 'Execute powershell script contents'
