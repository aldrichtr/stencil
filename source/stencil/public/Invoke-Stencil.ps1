
function Invoke-Stencil {
    [CmdletBinding()]
    param(
        # Path to the stencil
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [Alias('PSPath')]
        [string[]]$Path
    )
    begin {
        $Jobs = @{}

        Write-Debug "-- Begin $($MyInvocation.MyCommand.Name)"
        #region registration
        Reset-StencilOperationRegistry
        Register-StencilOperation 'copy' 'Copy-Item' -Description 'Copy Items from source to destination'
        Register-StencilOperation 'new' 'New-Item' -Description 'Copy Items from source to destination'
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

        Register-StencilOperation 'content' {
            param($params)
            Write-Debug "  testing that i can access $($current_job.env.testvar)"

            Write-Debug "  Content value is $($params.Value)"
            $result = $params.Value | Select-String -Pattern '\$\{(?<var>.+?)\}' -AllMatches
            $value = $params.Value
            if ($result.Matches.Count -gt 0) {
                $result.Matches | ForEach-Object {
                    $found = $_.Groups[0].Value
                    $var = $_.Groups[1].Value
                    $parts = $var -split '\.'
                    $descend = $current_job
                    foreach ($part in $parts) {
                        if ($descend.ContainsKey($part)) {
                            $descend = $descend[$part]
                        }
                        if (-not($descend -is [hashtable])) {
                            $value = $value -replace [regex]::Escape($found) , $descend
                        }
                    }
                }
            }
            Write-Debug "   transformed, it is $value"

            if ($params.Append) {
                'Adding Content {0} to {1}' -f $value, $params.Path | Write-Debug
                $params.Remove('Append')
                Add-Content @params
            } else {
                'Setting Content {0} to {1}' -f $value, $params.Path | Write-Debug
                $params.Remove('Append')
                Set-Content @params
            }
        } -Description 'Write content to a file'

        Register-StencilOperation 'expand' {
            param($params)
            if ($params.Keys -contains 'Destination') {
                $dest = $params.Destination
                $params.Remove('Destination')
                Invoke-EpsTemplate @params | Out-File $dest
            } else {
                Invoke-EpsTemplate @params
            }
        }
        #endregion registration

        $file_count = 0
    }
    process {
        foreach ($p in $Path) {
            try {
                $registry = Get-StencilOperationRegistry

                $config_file = Join-Path $p 'stencil.yml' -Resolve -ErrorAction Continue
                $file_count++
                Write-Debug "  Loading file $file_count - $config_file"
                $job_count = 0

                $config = Get-Content $config_file | ConvertFrom-Yaml -Ordered
                foreach ($job in $config.jobs) {
                    $job_count++
                    ## set up the context for when we invoke the steps:
                    $context_functions = @{}
                    $context_variables = [System.Collections.Generic.List[psvariable]]@()
                    $context_arguments = @()

                    ### we want the 'Jobs' table to be available to the operations

                    ## add an entry in the jobs table
                    $current_job = @{}
                    Write-Debug "  Added $job_count to Jobs table"

                    if ($job.Keys -contains 'id') {
                        Write-Debug "  job $job_count id set to $($job.id)"
                        $current_job['id'] = $job.id
                    }

                    if ($job.Keys -contains 'name') {
                        Write-Debug "  job $job_count name set to $($job.name)"
                        $current_job['name'] = $job.name
                    }

                    ## add any job "environment" variables
                    if ($job.Keys -contains 'env') {
                        $current_job.env = @{}
                        foreach ($var in $job.env.Keys) {
                            Write-Debug "  Adding $var to env table"
                            $current_job.env[$var] = $job.env[$var]
                        }
                    }
                    $Jobs[$job_count] = $current_job
                    ## process the steps now
                    $step_count = 0
                    $context_variables.Add( (Get-Variable 'Jobs') )
                    $context_variables.Add( (Get-Variable 'current_job'))
                    foreach ($step in $job.steps) {
                        $step_count++
                        $name = ($step.Keys)[0]
                        Write-Debug "  Step #$step_count is '$name'"

                        $context_arguments = $step[$name]

                        if ($registry.ContainsKey("$name")) {
                            Write-Debug "  Operation '$name' is registered"
                            [scriptblock]$sb = $registry[$name].Command
                            $sb.InvokeWithContext(
                                $context_functions,
                                $context_variables,
                                $context_arguments
                            )
                        } else {
                            Write-Warning "Operation '$name' is not registered"
                        }
                    }
                }
                Write-Debug "  Completed job #$job_count"
            } catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }
        Write-Debug "  Completed file #$file_count"
    }
    end {
        Write-Debug "-- End $($MyInvocation.MyCommand.Name)"
    }
}
