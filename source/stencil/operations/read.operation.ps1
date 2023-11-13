Register-StencilOperation 'read' {
    param($params)
    if ($null -ne $Job) {
        $read = Read-Host (-join (
                $PSStyle.Foreground.Cyan,
                $params.Prompt,
                ' ',
                $PSStyle.Reset
            ))
        Write-Debug "  Adding '$read' to env.$($params.Name)"
        $Job.env[$params.Name] = $read
    } else {
        Write-Debug "  I didn't get the Job variable"
    }

} -Description 'Prompt the user for information'
