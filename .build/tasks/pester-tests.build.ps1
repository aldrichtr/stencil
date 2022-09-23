#Requires -modules 'Pester', 'PSDkit'

#synopsis: Run the Pester tests in the Unit directory
task run_unit_tests {
    <#
        load each staging module
        get the configuration for Tests.UnitTests.Config
        get the result file from Tests.UnitTests.Result
        Set codecoverage options
        Invoke-Pester
        Save the result
    #>
    $mod_paths = @()
    foreach ($key in $Modules.Keys) {
        $mod = $Modules[$key]
        Write-Build Gray "  Loading $($mod.StagingModule)"
        $mod_paths += $mod.StagingModule
        Import-Module $mod.StagingModule -Force
    }

    if (($null -ne $Tests) -and ($Tests.Keys -contains 'UnitTest')) {
        Write-Build DarkGray "   (Getting configuration for 'UnitTest' from the Tests property)"
        if ($Tests.UnitTest.Keys -contains 'Config') {
            if (($Tests.UnitTest.Config -is [string]) -and
                (Test-Path $Tests.UnitTest.Config)) {
                Write-Build DarkGray "  Loading configuration $($Tests.UnitTest.Config)"
                $conf = Import-Psd $Tests.UnitTest.Config
            } elseif ($Tests.UnitTest.Config -is [hashtable]) {
                $conf = $Tests.UnitTest.Config
            }
        }
        if ($Tests.UnitTest.Keys -contains 'Result') {
            $pester_result_file = $Tests.UnitTest.Result
        } else {
            $pester_result_file = $null
        }
    }

    assert ($null -ne $conf) 'Could not load UnitTest configuration'
    if ($conf.CodeCoverage.Enabled) {
        Write-Build DarkBlue '  CodeCoverage is Enabled'
        Write-Build DarkBlue "  $($conf.CodeCoverage.OutputFormat) file $($conf.CodeCoverage.OutputPath)"
        $conf.CodeCoverage.Path = @(
            $mod_paths
        )
    }

    $pester_config = [PesterConfiguration]$conf
    $pester_config.Run.PassThru = $true
    $pester_config.Run.Exit = $true
    $pester_config.Output.Verbosity = 'Normal'

    $pester_result = Invoke-Pester -Configuration $pester_config | Out-Null

    if ($null -ne $pester_result_file) {
        $pester_result | Export-Clixml $pester_result_file
        Write-Build DarkBlue "  Writing pester results to $(Resolve-Path $pester_result_file -Relative)"
    }

}
#synopsis: Translate file and line number information in a coverage report for UnitTests
task convert_codecoverage {
    if ($Tests.UnitTest.Keys -contains 'Result') {
        $pester_result_file = $Tests.UnitTest.Result
    } else {
        Write-Build DarkYellow "  property 'Tests.UnitTest.Result' not set, looking in Artifact directory"
        #TODO: don't hardcode this path !
        $result_files = Get-ChildItem (Join-Path $Project.Path.Artifact 'tests') -Filter 'pester.unittest.result.xml'
        if ($result_files.Count -gt 0) {
            $pester_result_file = $result_files[0]
        }
    }
    assert (Test-Path $pester_result_file) "Could not find the pester result file"
    $pester_result = Import-Clixml $pester_result_file

    assert ($pester_result.CodeCoverage.CommandsAnalyzedCount -gt 0) "Pester results do not include coverage metrics"

    $converted_result = $pester_result.clone()

    $converted_result | Convert-LineNumber -SourceRoot (Join-Path $Project.Path.Source $Project.Name)
}
