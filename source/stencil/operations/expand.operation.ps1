Register-StencilOperation 'expand' {
    param($params)
    if (Test-Path $params.Path) {
        if ($params.Keys -contains 'Destination') {
            $dest = $params.Destination
            $params.Remove('Destination')
            Invoke-EpsTemplate @params | Out-File $dest
        } else {
            Invoke-EpsTemplate @params
        }
    } else {
        Write-Warning "template $($params.Path) could not be found"
    }
}
