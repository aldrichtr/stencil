

function Add-BuildModuleTask {
    param(
        [Parameter(
            Position = 0,
            Mandatory
        )]
        [string]$Name,

        [Parameter(
            Position = 1
        )]
        [switch]$Stage
    )



    task $Name -Data $PSBoundParameters -Source $MyInvocation {
        foreach ($key in $Modules.Keys) {
            $mod = $Modules[$key]
            $options = @{
                SourcePath                 = $mod.SourceManifest
                UnVersionedOutputDirectory = $Task.Data.Stage
                OutputDirectory            = [System.IO.Path]::GetRelativePath( $mod.Source, $Project.Path.Staging)
                PassThru                   = $true
            }

            Write-Build DarkBlue "  $($Task.Data.Stage ? 'Stag' : 'Build')ing the module"
            $build_result = Build-Module @options

            if ($build_result) {
                Write-Build DarkBlue ((
                    "  - Build-Module Results for $($build_result.Name) v$($build_result.Version)",
                    "    - Manifest : $(Resolve-Path $build_result.Path -Relative)",
                    "    - Description: $($build_result.Description)",
                    "    - Root module: $($build_result.RootModule)") -join "`n")
            }
        }
    }
}

Set-Alias module Add-BuildModuleTask
