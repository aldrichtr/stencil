
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
        # The id of the job to return
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
                Write-Debug 'No path given. Looking for stencils in the default directory'
                $Path = (Resolve-Path (Join-Path $pathConfig.Root $pathConfig.Jobs))
                | Select-Object -ExpandProperty Path
                Write-Debug "- $Path"
            } catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }
        foreach ($p in $Path) {
            Write-Debug "Looking for stencil files in $p"
            if ($p | Test-Path) {
                $stencilFiles = Get-ChildItem $p -Recurse -Filter $config.Default.StencilFile
                if ($null -ne $stencilFiles) {
                    Write-Debug "$($stencilFiles.Count) stencil files found"
                    foreach ($stencilFile in $stencilFiles) {
                        Write-Debug "Processing stencil file $($stencilFile.FullName)"
                        $stencilInfo = Get-StencilInfo $stencilFile
                        if ($null -ne $stencilInfo) {
                            Write-Debug "  Stencil $($stencilInfo.name) has scope $($stencilInfo.scope)"
                            if (($stencilInfo.scope -eq [JobScope]::global) -or $All) {
                                if ((-not ($PSBoundParameters.ContainsKey('Id'))) -or
                                    ($stencilInfo.Id -in $Id)) {
                                    $stencilInfo
                                }
                            }
                        } else {
                            Write-Verbose "No stencil information found in $stencilFile"
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
