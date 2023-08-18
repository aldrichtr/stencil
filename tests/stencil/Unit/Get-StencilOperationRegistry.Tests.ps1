
Describe 'Private function Get-StencilOperationRegistry' -Tag @('unit', 'private') {
    Context 'The command is available from the module' {
        BeforeAll {
            $command = Get-Command 'Get-StencilOperationRegistry'
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

    Context 'The Operation Registry is requested the first time' {
        BeforeAll {
            if ($null -ne $script:StencilOperationRegistry) {
                Remove-Variable StencilOperationRegistry -Scope Script
            }
        }
        It 'Should return an empty hashtable' {
            $registry = Get-StencilOperationRegistry
            $registry.Keys.Count | Should -Be 0
        }
    }
}
