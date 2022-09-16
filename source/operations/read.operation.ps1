Register-StencilOperation 'read' {
    param($params)
    if ($null -ne $current_job) {
        Write-Debug "current job is : $($current_job.Keys -join ', ')"
        Write-Debug "  reading input from host during '$($current_job.name)'"
        $read = Read-Host $params.Prompt
        Write-Debug "  Adding '$read' to current_job.env.$($params.var)"
        $current_job.env[$params.var] = $read
    } else {
        Write-Debug "  I didn't get the current_job variable"
    }

} -Description 'Prompt the user for information'
