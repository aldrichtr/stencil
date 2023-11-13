
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
        # collect the names so we can "guarentee uniqueness"
        $jobNames = [System.Collections.ArrayList]::new()
        # tags associated with the stencil
        $stencilTags = [System.Collections.ArrayList]::new()
        # tags that will be inherited by jobs in this stencil
        $jobTags = [System.Collections.ArrayList]::new()

    }
    process {
        foreach ($p in $Path) {
            $stencil = Get-Content $p | ConvertFrom-Yaml @parserOptions
            if ($stencil.jobs -isnot [hashtable]) {
                throw "in '$p' jobs table is not in the correct format"
            }


            #-------------------------------------------------------------------------------
            #region Environment

            # Start with the current Environment
            $environmentTable =  [System.Environment]::GetEnvironmentVariables()

            # add any fields defined in env: in the stencil.
            #! Any common fields will be overwritten
            if ($null -ne $stencil.env) {
                #TODO (job): Are there certain variables we should add by default?
                $environmentTable = $environmentTable | Update-Object $stencil.env
            }

            #endregion Environment
            #-------------------------------------------------------------------------------

            #-------------------------------------------------------------------------------
            #region Tags
            # add any tags defined in tags: in the stencil
            [void]$stencilTags.Clear()
            [void]$jobTags.Clear()

            if ($null -ne $stencil.tags) {
                foreach ($tag in $stencil.tags) {
                    [void]$stencilTags.Add($tag)
                    #! Any tags that do not start with '.' will be inherited by each job
                    if ($tag.indexOf('.') -ne 0) {
                        Write-Debug "Tag $tag will not be inherited"
                        [void]$jobTags.Add($tag)
                    }
                }
            }
            #endregion Tags
            #-------------------------------------------------------------------------------


            :jobs foreach ($key in $stencil.jobs.Keys) {

                if ($jobNames -contains $key) {
                    Write-Warning "Attempt to redefine '$key' in '$p', Skipping"
                    continue jobs
                }
                #! not present, add it to the list
                [void]$jobNames.Add($key)

                $job = $stencil.jobs[$key]

                #! The default scope is global
                if ([string]::IsNullorEmpty($job['scope'])) {
                    $job['scope'] = [JobScope]::global
                }
                $job['Config'] = $job
                $job['output'] = @{}
                $job['PSTypeName'] = 'Stencil.JobInfo'
                $job['Id'] = $key
                $job['SourceDir'] = (Get-Item $p).Directory.FullName
                $job['Path'] = (Get-Item $p).FullName
                $job['CurrentDir'] = '' # place holder, set at runtime
                $job['Version'] = [semver]($stencil.Version) ?? ''

                if ($job.Keys -notcontains 'env') {
                    # ensure there is an 'env' table to write to
                    $job['env'] = @{}
                }

                if ($jobTags.Count -gt 0) {
                    # Tag inheritence
                    if ($job.Keys -notcontains 'tags') {
                        $job['tags'] = @()
                    }
                    $job.tags = @( $job.tags + $jobTags ) | Sort-Object -Unique
                }
                #! if there were no inherited tags but there are tags in the job,
                #! then there is no need to modify them

                #! merge the environment table
                $job.env = $job.env | Update-Object $environmentTable


                $jobObject = [PSCustomObject]$job
                $jobObject | Write-Output
            }
        }
    }
    end {
        Write-Debug "-- End $($MyInvocation.MyCommand.Name)"
    }
}
