
function Get-StencilInfo {
    <#
    .SYNOPSIS
        Get the information for each job defined in the given stencil
    .DESCRIPTION
        `Get-StencilInfo` is used to parse the stencil manifest and return an object representing each job defined
        in the file.
    #>
    [CmdletBinding()]
    param(
        # The path to the stencil file to load
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [Alias('PSPath')]
        [string[]]$Path
    )
    begin {
        Write-Debug "-- Begin $($MyInvocation.MyCommand.Name)"
        $config = Import-Configuration
        $parser_options = $config.Parser
        $job_names = @() # collect the names so we can "guarentee uniqueness"
    }
    process {
        foreach ($p in $Path) {
            $stencil = Get-Content $p | ConvertFrom-Yaml @parser_options
            if ($stencil.jobs -isnot [hashtable]) {
                throw "in '$p' jobs table is not in the correct format"
            }
            foreach ($key in $stencil.jobs.Keys) {
                if ($job_names -notcontains $key) {
                    #! not present, add it to the list
                    $job_names += $key

                    $job = $stencil.jobs[$key]
                    $job['PSTypeName'] = 'Stencil.JobInfo'
                    $job['id'] = $key
                    $job['SourceDir'] = (Get-Item $p).Directory.FullName
                    $job['Path'] = (Get-Item $p).FullName
                    $job['CurrentDir'] = '' # place holder, set at runtime
                    $job['Version'] = $stencil.Version ?? ''

                    if ($job.Keys -notcontains 'env') {
                        # ensure there is an 'env' table to write to
                        $job.env = @{}
                    }

                    [PSCustomObject]$job | Write-Output

                } else {
                    Write-Warning "Attempt to redefine '$key' in '$p', Skipping"
                }
            }
        }
    }
    end {
        Write-Debug "-- End $($MyInvocation.MyCommand.Name)"
    }
}
