Register-StencilOperation 'run' {
    param($params)
    $script = [scriptblock]::create($params.shell)
    & $script
} -Description 'Execute powershell script contents'
