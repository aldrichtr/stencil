
function Invoke-Stencil {
    [CmdletBinding()]
    param(
        # One or more jobs to invoke
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [string[]]$Name,

        # An alternate path to the root of the stencil folders
        [Parameter(
        )]
        [string]$Path
    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"

        Write-Debug '  loading configuration'
        $config = Import-Configuration
        $reg_options = $config.Registry

        <#------------------------------------------------------------------
          1.  Load the operations registry
        ------------------------------------------------------------------#>

        Reset-StencilOperationRegistry

        Write-Debug "  Loading Operations from $(Resolve-Path $reg_options.Path)"
        Get-ChildItem @reg_options | ForEach-Object {
            Write-Verbose "   - Sourcing $($_.BaseName)"
            . $_.FullName
        }

        $script:Context = @{}
        $script:Jobs = @{}
    }
    process {
        <#------------------------------------------------------------------
        2.  Determine all of the paths that stencils should be loaded from

          a. The path(s) given as a parameter
          b. The $StencilPath variable
          c. The default location ($config.Default.Directory)
          d. The current directory
        ------------------------------------------------------------------#>
        if (-not($PSBoundParameters.ContainsKey('Path'))) {
            if ($null -ne $StencilPath) {
                $Path = ($StencilPath -split ';')
            } elseif (Test-Path $config.Default.Directory) {
                $Path = $config.Default.Directory
            } else {
                $Path = (Get-Location).Path
            }
        }

        Write-Debug "  Looking for stencils in $Path"
        $script:Jobs = Get-Stencil -Path $Path
        Write-Debug "  Loaded $($script:Jobs.Count) jobs"

        $script:Jobs | Where-Object {$Name -contains $_.Id} | Invoke-StencilJob
    }
    end {
        Write-Debug "-- End $($MyInvocation.MyCommand.Name)"
    }
}