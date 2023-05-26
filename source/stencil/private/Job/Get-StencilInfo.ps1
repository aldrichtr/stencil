
function Get-StencilInfo {
    <#
    .SYNOPSIS
        Get the information for each job defined in the given stencil
    .DESCRIPTION
        `Get-StencilInfo` is used to parse the stencil manifest and return an object representing each job defined
        in the file.
    #>
    [OutputType('Stencil.JobInfo')]
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
        $parserOptions = $config.Parser
        $jobNames = @() # collect the names so we can "guarentee uniqueness"
    }
    process {
        foreach ($p in $Path) {
            $stencil = Get-Content $p | ConvertFrom-Yaml @parserOptions
            if ($stencil.jobs -isnot [hashtable]) {
                throw "in '$p' jobs table is not in the correct format"
            }
            foreach ($key in $stencil.jobs.Keys) {
                if ($jobNames -notcontains $key) {
                    #! not present, add it to the list
                    $jobNames += $key

                    $job = $stencil.jobs[$key]

                    if ([string]::IsNullorEmpty($job['scope'])) {
                        $job['scope'] = [JobScope]::global
                    }
                    $job['PSTypeName'] = 'Stencil.JobInfo'
                    $job['id'] = $key
                    $job['SourceDir'] = (Get-Item $p).Directory.FullName
                    $job['Path'] = (Get-Item $p).FullName
                    $job['CurrentDir'] = '' # place holder, set at runtime
                    $job['Version'] = [semver]($stencil.Version) ?? ''

                    if ($job.Keys -notcontains 'env') {
                        # ensure there is an 'env' table to write to
                        $job.env = @{}
                    }
                    $jobObject = [PSCustomObject]$job
                    $jobObject | Write-Output

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
