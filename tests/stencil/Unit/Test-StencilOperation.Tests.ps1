
Describe 'Testing the private function Test-StencilOperation' -Tag @('unit', 'private') {
    Context 'The command is available from the module' {
        BeforeAll {
            $command = Get-Command 'Test-StencilOperation'
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
    Context "When the 'copy' operation is registered" -ForEach @(
        @{
            Name = 'copy'
            Value = $true
        }
        @{
            Name = 'new'
            Value = $false
        }
    ){
        BeforeAll {
            Reset-StencilOperationRegistry
            $options = @{
                Name        = 'copy'
                Command     = 'Copy-Item'
                Description = 'Copy Path to Destination'
            }
            Register-StencilOperation @options
        }

        It 'Should return <Value> when the <Name> operation is tested' {
            Test-StencilOperation $Name | Should -Be $Value
        }
    }
}
