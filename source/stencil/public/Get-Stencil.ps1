
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
        # Specifies a path to one or more locations.
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [Alias('PSPath')]
        [string[]]$Path
    )
    begin {
        Write-Debug "-- Begin $($MyInvocation.MyCommand.Name)"
        $config = Import-Configuration
    }
    process {
        if (-not($PSBoundParameters.ContainsKey('Path'))) {
            $Path = $config.Default.Directory
        }
        foreach ($p in $Path) {
            Get-ChildItem $p -Recurse -Filter $config.Default.StencilFile | ForEach-Object {
                Get-StencilInfo $_ | Write-Output
            }
        }
    }
    end {
        Write-Debug "-- End $($MyInvocation.MyCommand.Name)"
    }
}
