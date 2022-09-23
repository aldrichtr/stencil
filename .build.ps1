#Requires -modules 'InvokeBuild'

param(
    # Workflow configuration file
    [Parameter(
    )]
    [string]$Workflows = (
        property Workflows "$BuildRoot\.build\workflow.ps1"
    )
)

process {
    if (Test-Path $Workflows) {
        # $workflow = Get-Content $Workflows | ConvertFrom-Yaml

        # foreach ($job in $workflow.Keys) {
        #     $step = $workflow[$job]
        #     task $job $step
        # }
        . $Workflows
    }
}

begin {
    function writeHeader([string]$Message, [string]$Description) {
        $WIDTH = 80
        $m_spaces = $WIDTH - ($Message.Length + 3 <#startmark+1space#> + 2<#endmark#>)
        if ($Description.Length -gt ($WIDTH - 5)) {
            $Description = $Description.Substring(0, ($WIDTH - 6))
        }
        $d_spaces = $WIDTH - ($Description.Length + 3 <#startmark+1space#> + 2<#endmark#>)
        Write-Host -ForegroundColor Cyan -Object ('-' * $WIDTH)
        Write-Host -ForegroundColor Cyan -Object "-- $Message$(' ' * $m_spaces)--"
        Write-Host -ForegroundColor Cyan -Object "-- $Description$(' ' * $d_spaces)--"
        Write-Host -ForegroundColor Cyan -Object ('-' * $WIDTH)
    }

    function writeFooter([string]$Message) {
        $WIDTH = 80
        $m_dashes = $WIDTH - ($Message.Length + 3 <#startmark+1space#> + 1 <#trailspace#>)
        Write-Host -ForegroundColor Cyan -Object ("-- $Message $('-' * $m_dashes)")
    }

    $BuildScripts = [System.Collections.ArrayList]@()

    writeHeader 'Phase 0: Load build scripts'

    ## do our best to find a bootstrap script
    ## by convention it should be:
    ## - ./.build.config.ps1
    ## - ./.build/config/.build.ps1
    $default_bootstrap = @(
            (Join-Path $BuildRoot '.build/config/.build.ps1')
    (Join-Path $BuildRoot '.build.config.ps1')
    )

    <#------------------------------------------------------------------
      1.  Bootstrap our main config
    ------------------------------------------------------------------#>
    if ($null -eq $BeforeBuildScript) {
        foreach ($def in $default_bootstrap) {
            if (Test-Path $def) {
                $BeforeBuildScript = (property BeforeBuildScript $def)
            }
        }

    }

    if ($null -eq $BeforeBuildScript) {
        ## Probably means the .build.ps1 script was copied here but not it's supporting files....
        Write-Warning 'No bootstrap build script found'
    } else {
        Write-Host "  Bootstrap Build script : [$(Resolve-Path $BeforeBuildScript -Relative)]" -ForegroundColor DarkGray
        . $BeforeBuildScript
    }

    <#------------------------------------------------------------------
      2.  Check for additional config scripts
    ------------------------------------------------------------------#>
    if ($null -eq $BuildConfig) {
        if (Test-Path (Join-Path $BuildRoot '.build\config')) {
            $BuildConfig = (property BuildConfig (Join-Path $BuildRoot '.build\config'))
        }
    }
    if (Test-Path $BuildConfig) {
        Write-Host '  Loading properties (Config) scripts' -ForegroundColor DarkGray
        $BuildScripts += (Get-ChildItem "$BuildConfig\*.ps1" -Exclude '.*.ps1')
    }


    <#------------------------------------------------------------------
    3.  Check for additional function and task definitions
    ------------------------------------------------------------------#>
    if ($null -eq $BuildTasks) {
        if (Test-Path (Join-Path $BuildRoot '.build\tasks')) {
            $BuildTasks = (property BuildTasks (Join-Path $BuildRoot '.\.build\tasks'))
        }
    }
    if (Test-Path $BuildTasks) {
        # load task function definitions before task implementation scripts
        Write-Host '  Loading function definitions (task) scripts' -ForegroundColor DarkGray
        $BuildScripts += (Get-ChildItem "$BuildTasks\*.tasks.ps1" -Exclude '.*.tasks.ps1')
        Write-Host '  Loading task definitions (build) scripts' -ForegroundColor DarkGray
        $BuildScripts += (Get-ChildItem "$BuildTasks\*.build.ps1" -Exclude '.*.build.ps1')
    }

    foreach ($script in $BuildScripts) {
        if (Test-Path $script) {
            . $script.FullName
        }
    }

    writeFooter 'End Phase 0'
    <#------------------------------------------------------------------
      4.  Main Invoke-Build Script
    ------------------------------------------------------------------#>
    Enter-Build {
        $script:hlevel = -1
        $script:leader = '| '
        Write-Build Gray ('=' * 80)
        Write-Build Gray "# `u{E7A2} PowerShell BuildTools "
        Write-Build DarkGray "# BuildTools project running in '$BuildRoot'"
        if ($Header -notlike 'minimal') {
            Write-Host ('-' * 80) -ForegroundColor '#1d2951'
            Write-Build White 'Project directories:'
            foreach ($key in $Project.Path.Keys) {
                $projPath = $Project.Path[$key]
                if (Test-Path $projPath) {
                    Write-Build Gray (
                        ' - {0,-16} {1}' -f $key,
                        ((Get-Item $projPath) |
                            Resolve-Path -Relative -ErrorAction SilentlyContinue)
                    )
                } else {
                    Write-Build DarkGray (' - {0,-16} {1}' -f $key, "(missing) $projPath" )
                }
            }
        }
        Write-Build Gray ('=' * 80)
    }

}



end {
    Set-BuildHeader {
        param($Path)
        writeHeader "Begin Task: $($Task.Name.ToUpper() -replace '_', ' ')" (Get-BuildSynopsis $Task)
        # Write-Build White ('{0}+- [{1}] {2}' -f ($leader * $hlevel), $Task.Name, $synopsis)
        # Write-Build DarkYellow "$($Task.InvocationInfo.ScriptName):$($Task.InvocationInfo.ScriptLineNumber)"
    }

    Enter-BuildTask {
        $script:hlevel++
        #    Write-Build DarkYellow "Entering Task ^$hlevel"
    }

    Enter-BuildJob {
        $script:hlevel++
        #    Write-Build DarkYellow "Entering Job ^$hlevel"
    }
    Exit-BuildJob {
        $script:hlevel--
        #    Write-Build DarkYellow "Exiting Job ^$hlevel"
    }
    Exit-BuildTask {
        $script:hlevel--
        #    Write-Build DarkYellow "Exiting Task ^$hlevel"

    }

    Set-BuildFooter {
        param($Path)
        writeFooter "End Task: $($Task.Name.ToUpper() -replace '_', ' ')"
    }
    Exit-Build { }

}
