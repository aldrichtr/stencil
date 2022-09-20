
Describe 'Testing the private function Test-StencilJob' -Tag @('unit', 'private') {
    Context 'The command is available from the module' {
        BeforeAll {
            $command = Get-Command 'Test-StencilJob'
        }

        It 'Should load without error' {
            $command | Should -Not -BeNullOrEmpty
        }

        It 'Should pass PSScriptAnalyzer Rule <_.RuleName>' -Tag @('analyzer') -ForEach @(Get-ScriptAnalyzerRule) {
            $result = Invoke-ScriptAnalyzer -ScriptDefinition $command.Definition -IncludeRule $_.RuleName
            $result | Should -BeNullOrEmpty -Because (
                ".`n$($PSStyle.Foreground.BrightWhite){0} on line {1} {2}`n`n.$($PSStyle.Reset)" -f $result.Severity, $result.Line, $result.Message )
        }
    }

    Context "When the job 'test_job1' is registered" -ForEach @(
        @{
            Name  = 'test_job1'
            Value = $true
        }
        @{
            Name  = 'another_test_job2'
            Value = $false
        }
    ) {
        BeforeAll {
            InModuleScope -ModuleName stencil {
                $script:Jobs = @(
                    [PSCustomObject]@{
                        PSTypeName = 'Stencil.JobInfo'
                        Id         = 'test_job1'
                    }
                )
            }
        }

        It 'Should return <Value> when <Name> is tested' {
            Test-StencilJob $Name | Should -Be $Value
        }
    }

}
