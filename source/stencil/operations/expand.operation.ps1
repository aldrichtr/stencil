Register-StencilOperation 'expand' {
    param($params)
    if (($params.Keys -contains 'Binding') -and ($params.Binding -is [string])) {
        $bind = Get-Variable ($params.Binding -replace '^\$', '')
        if ($bind -is [hashtable]) {
            $params.Binding = $bind
        } else {
            Write-Error "$($params.Binding) is not a hashtable"
        }
    } else {
        # HACK: Invoke-EpsTemplate expects a hashtable so we need to convert
        #  the job object, but we still want to reference it as 'Job'
        # in the template so we add all under the 'Job' key
        $jobHash = @{
            Job = @{}
        }
        $Job.PSObject.Properties | ForEach-Object {
            [void]$jobHash.Job.Add($_.Name, $_.Value)
        }
        # Safe tells EPS to use the Binding
        if ($params.Keys -notcontains 'Safe') {
            $params['Safe'] = $true
        }
        $params.Binding = $jobHash
    }
    if (Test-Path $params.Path) {
        if ($params.Keys -contains 'Destination') {
            $dest = $params.Destination
            [void]$params.Remove('Destination')
            Invoke-EpsTemplate @params | Out-File $dest
        } else {
            Invoke-EpsTemplate @params
        }
    } else {
        Write-Warning "template $($params.Path) could not be found"
    }
}
