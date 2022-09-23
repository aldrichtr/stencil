<#




.SYNOPSIS
    BuildTool Configuration file
.DESCRIPTION
    Each parameter uses the 'property' alias of Invoke-Build, which looks in:
    - Session
    - Environment
    - Default
    to determine the value.  So, each variable can be set (either as a parameter,
    script variable, or Environment variable) prior to this script
    being run, and that value will be used instead of the one set here.
.NOTES
    ---
    stencil:
      template: build_config
      version: 0.1
      date: 2022-09-23 12:45
    ---
#>
param(
    [Parameter()]
    [string]$BuildTools = (
        property BuildTools "$BuildRoot\.build"
    ),

    [Parameter()]
    [string]$BuildConfig = (
        property BuildConfig "$BuildTools\config"
    ),

    # an array of paths to additional task files
    [Parameter()]
    [string[]]$BuildTasks = (
        property BuildTasks @("$BuildTools\tasks")
    ),

    # Options for PSDepend2
    [Parameter()]
    [hashtable]$Dependencies = (
        property Dependencies @{
            Tags = @('dev')
        }
    ),

    # BuildTools header output
    [Parameter()]
    [ValidateSet('minimal', 'normal', 'verbose')]
    [string]
    $Header = (property Header 'verbose'),

    [Parameter()]
    [hashtable]$Project = (
        property Project @{
            Name = 'stencil'
            Path = @{
                Source   = "$BuildRoot/source"
                Docs     = "$BuildRoot/docs"
                Staging  = "$BuildRoot/stage"
                Tests    = "$BuildRoot/tests"
                Artifact = "$BuildRoot/out"
            }
        }
    ),


    [Parameter()]
    [hashtable]$Modules = (
        property Modules @{
            stencil = @{
                Root      = $true
                Types     = @('enum', 'classes', 'private', 'public')
                Copy      = @(
                    @{
                        Path = 'operations'
                        Recurse = $true
                    }
                )
                LoadOrder = $null
            }
        }
    ),

    <#
    The build needs the following for each "type" of test:
    - PesterConfiguration
    - Path to store Invoke-Pester output object (clixml)
    #>
    [Parameter()]
    [hashtable]$Tests = (
        property Tests @{
            UnitTest = @{
                Result = (Join-Path -Path $Project.Path.Artifact -ChildPath 'tests' -AdditionalChildPath 'pester.unittest.results.xml')
                Config = @{
                    Run    = @{
                        Path     = "$($Project.Path.Tests)/Unit"
                        PassThru = $true
                        Exit     = $true
                    }
                    Filter = @{
                        ExcludeTag = @('analyzer')
                    }
                    CodeCoverage = @{
                        Enabled = $true
                        OutputFormat = 'JaCoCo'
                        OutputPath = (Join-Path -Path $Project.Path.Artifact -ChildPath 'tests' -AdditionalChildPath 'pester.unittest.codecoverage.jacoco.xml')
                    }
                }
            }
        }
    )
)

foreach ($key in $Modules.Keys) {
    $Modules[$key].Source          = (Join-Path -Path $Project.Path.Source -ChildPath $key)
    $Modules[$key].SourceManifest  = (Join-Path -Path $Modules[$key].Source -ChildPath "$key.psd1")
    $Modules[$key].SourceModule    = (Join-Path -Path $Modules[$key].Source -ChildPath "$key.psm1")
    $Modules[$key].Staging         = (Join-Path -Path $Project.Path.Staging -ChildPath $key)
    $Modules[$key].StagingManifest = (Join-Path -Path $Modules[$key].Staging -ChildPath "$key.psm1")
    $Modules[$key].StagingModule   = (Join-Path -Path $Modules[$key].Staging -ChildPath "$key.psm1")
}
