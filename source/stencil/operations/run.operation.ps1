Register-StencilOperation 'run' {
    param($params)
    Write-Debug "  Running script:`n$('-' * 80)`n$($params.script)`n$('-' * 80)"
    $script = [scriptblock]::create($params.script)
    $script.invoke()
} -Description 'Execute powershell script contents'
