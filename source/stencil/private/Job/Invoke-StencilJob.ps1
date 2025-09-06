
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
        $state = Get-StateTable
        $stepCount = 1
        <# set up the context for when we invoke the steps:
        # Functions are in the form of
        @{
             String = Scriptblock
        }
        The `String` will be available as a function to the running job
        Similar to helper functions in other systems like handlebars
        #>
        $contextFunctions = @{}
        ## These can be variables from the current session or new ones added
        ## such as creating $_ or $input, etc.
        #TODO: Consider creating a variable for the stencil file so that operations can point to an error
        $contextVariables = [System.Collections.Generic.List[psvariable]]@()
        ## These are passed to the steps as parameters
        $contextArguments = @()
    }
    process {
        Write-Debug "  Invoking job $($Job.Id)"
        if (-not($Job.psobject.properties.Name -contains 'env')) {
            $Job | Add-Member -NotePropertyName env -NotePropertyValue @{}
        }
        $state.CurrentJob = $Job.Id
        <#------------------------------------------------------------------
          1.  Set up the environment
        ------------------------------------------------------------------#>
        #TODO: What if the user wants the output in a different location?
        $Job.CurrentDir = (Get-Location).Path
        $Job.cwd = $Job.CurrentDir
        $Job.src = $Job.SourceDir
        :step foreach ($step in $Job.steps) {
            Write-Debug "`n$('-' * 80)`n-- STEP #$stepCount`n$('-' * 80)"
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
            # the Operation name to be called
            $operation = $step.Keys[0]

            # These will be passed to the step as parameters
            $params = @{}

            # the step configuration from the file
            $config = $step[$operation]

            Write-Debug "  Step #$stepCount is '$operation'"
            Write-Debug '  The environment is: '
            Write-Debug "    - SourceDir => $($Job.SourceDir)"
            Write-Debug "    - CurrentDir => $($Job.CurrentDir)"
            Write-Debug "    - {cwd} => $($Job.cwd)"
            Write-Debug "    - {src} => $($Job.src)"
            foreach ($key in $Job.env.Keys) {
                '    - env.{0} => {1}' -f $key , $Job.env[$key] | Write-Debug
            }

            Write-Debug '  The step configuration is:'
            foreach ($key in $config.Keys) {
                '    - {0} => {1}' -f $key , $config.$key | Write-Debug
            }

            Write-Debug '  Expanding tokens in configuration params:'
            :key foreach ($key in $config.Keys) {
                Write-Debug "   - Processing $key"
                if ($null -eq $config.$key) {
                    Write-Debug "  $key was null"
                    $params[$key] = ''
                } else {
                    Write-Debug "     - $key is a $($config.$key.GetType())"
                    if ($config.$key -is [string] ) {
                        Write-Debug "   - Before transformation: $($config.$key)"
                        $params[$key] = ($config.$key | Expand-StencilValue -Data $Job)
                        Write-Debug "   - transformed $key => $($params[$key])"
                    } else {
                        Write-Debug " $($config.$key) is not a string.  Adding to params"
                        $params[$key] = $config.$key
                    }
                }
            }

            Write-Debug '  The final configuration params are:'
            foreach ($key in $params.Keys) {
                '    - {0} => {1}' -f $key , $params.$key | Write-Debug
            }

            $contextArguments = $params

            if ($operation | Test-StencilOperation) {
                Write-Debug "  Operation '$operation' is registered.  Running"
                try {
                    [scriptblock]$sb = ($operation | Get-StencilOperation)
                    $sb.InvokeWithContext(
                        $contextFunctions,
                        $contextVariables,
                        $contextArguments
                    )
                } catch {
                    $PSCmdlet.ThrowTerminatingError($_)
                }
            } elseif ($operation | Test-StencilJob) {
                Write-Debug "  Job '$operation' is registered.  Running"
                $operation | Get-StencilJob | Invoke-StencilJob
            } else {
                Write-Verbose "  '$operation' is not recognized as an operation or job.  Skipping"
            }
            $stepCount++
        }
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
