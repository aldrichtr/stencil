
function Invoke-StencilJob {
    <#
    .SYNOPSIS
        Run the given stencil job
    .DESCRIPTION
        `Invoke-StencilJob` runs a job defined in a stencil manifest.
    #>
    [CmdletBinding()]
    param(
        # Stencil job to run
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [PSTypeName('Stencil.JobInfo')]$Job
    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
        $step_count = 1
        ## set up the context for when we invoke the steps:
        $context_functions = @{}
        $context_variables = [System.Collections.Generic.List[psvariable]]@()
        $context_arguments = @()

    }
    process {
        Write-Debug "  Invoking job $($Job.Id)"
        <#------------------------------------------------------------------
          1.  Set up the environment
        ------------------------------------------------------------------#>
        $Job.CurrentDir = (Get-Location).Path
        $step_count = 0
        foreach ($step in $Job.steps) {
            Write-Debug "`n$('-' * 80)`n-- STEP #$step_count`n$('-' * 80)"
            <# the way the parser creates the step is like this:
            - new:
            foo: bar
            blah: baz
            becomes
            @{
                new = @{
                    foo = bar
                    blah = baz
                }
            }
            #>
            $cmd = $step.Keys[0]
            $options = $step[$cmd]


            Write-Debug "  Step #$step_count is '$cmd'"
            Write-Debug '  The environment is: '
            Write-Debug "    - SourceDir => $($Job.SourceDir)"
            Write-Debug "    - CurrentDir => $($Job.CurrentDir)"
            foreach ($key in $Job.env.Keys) {
                '    - {0} => {1}' -f $key , $Job.env[$key] | Write-Debug
            }

            Write-Debug '  The configuration options are:'
            foreach ($key in $options.Keys) {
                '    - {0} => {1}' -f $key , $options[$key] | Write-Debug

            }

            Write-Debug '  Expanding tokens in configuration options:'
            foreach ($key in $options.Keys) {
                if ($options[$key] -is [string] ) {
                    $options[$key] = ($options[$key] | Expand-StencilValue -Data $Job)
                    Write-Debug "   - transformed $key => $($options[$key])"
                }
            }

            $context_arguments = $options

            if ($cmd | Test-StencilOperation) {
                Write-Debug "  Operation '$cmd' is registered.  Running"
                [scriptblock]$sb = ($cmd | Get-StencilOperationCommand)
                $sb.InvokeWithContext(
                    $context_functions,
                    $context_variables,
                    $context_arguments
                )
            } elseif ($cmd | Test-StencilJob) {
                Write-Debug "  Job '$cmd' is registered.  Running"
                $script:Jobs[$cmd] | Invoke-StencilJob
            } else {
                Write-Verbose "  '$cmd' is not recognized as an operation or job.  Skipping"
            }
            $step_count++
        }
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
