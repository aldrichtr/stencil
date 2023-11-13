
function Get-Stencil {
    <#
    .SYNOPSIS
        Get all the stencils in the given path
    .DESCRIPTION
        `Get-Stencil` returns a `Stencil.JobInfo` object for each job defined in the stencil manifests found in each
        path given.  If no paths are given, the Default.Directory from the configuration is used.
    #>
    [CmdletBinding()]
    param(
        # The id of the jobs to return
        [Parameter(
            Position = 0
        )]
        [string[]]$Id,

        # Specifies a path to one or more locations.
        [Parameter(
            Position = 1,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [Alias('PSPath')]
        [string[]]$Path,

        # Show all stencils, including shared and private
        [Parameter(
        )]
        [switch]$All
    )
    begin {
        Write-Debug "-- Begin $($MyInvocation.MyCommand.Name)"

        $config = Import-Configuration
        $pathConfig = $config.Default.Path
    }
    process {
        if (-not($PSBoundParameters.ContainsKey('Path'))) {
            try {
                $Path = (Resolve-Path (Join-Path $pathConfig.Root $pathConfig.Jobs))
            } catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }
        #TODO: Create a yaml schema file for stencils
        foreach ($p in $Path) {
            Get-ChildItem $p -Recurse -Filter $config.Default.StencilFile | ForEach-Object {
                foreach ($stencil in (Get-StencilInfo $_)) {
                    Write-Debug "  Stencil $($stencil.name) has scope $($stencil.scope)"
                    if (($stencil.scope -eq [JobScope]::global) -or $All) {
                        if ((-not ($PSBoundParameters.ContainsKey('Id'))) -or
                            ($stencil.Id -in $Id)) {
                            $stencil | Write-Output
                        }
                    }
                }
            }
        }
    }
    end {
        Write-Debug "-- End $($MyInvocation.MyCommand.Name)"
    }
}
