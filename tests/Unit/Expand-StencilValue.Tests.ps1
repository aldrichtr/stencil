
Describe 'Private function Expand-StencilValue' {
    Context 'The function is available from the module' {
        BeforeAll {
            $command = Get-Command 'Expand-StencilValue'
        }

        It 'Should load without error' {
            $command | Should -Not -BeNullOrEmpty
        }

        It 'Should pass PSScriptAnalyzer Rule <_.RuleName>' -ForEach @(Get-ScriptAnalyzerRule) -Tag @('analyzer') {
            $result = Invoke-ScriptAnalyzer -ScriptDefinition $command.Definition -IncludeRule $_.RuleName
            $result | Should -BeNullOrEmpty -Because (
                ".`n$($PSStyle.Foreground.BrightWhite){0} on line {1} {2}`n`n.$($PSStyle.Reset)" -f $result.Severity, $result.Line, $result.Message )
        }
        Context 'The parameters are set correctly' -ForEach @(
            @{
                Name      = 'Value'
                Mandatory = $false
                Set       = '__AllParameterSets'
            }
        ) {
            It 'Should accept the <name> Parameter' {
                if ($Mandatory) {
                    $command | Should -HaveParameter $Name -Mandatory
                } else {
                    $command | Should -HaveParameter $Name
                }
            }
            It 'Should be a member of the <set> ParameterSet' {
                $command.Parameters[$Name].Attributes.ParameterSetName | Should -Be $Set
            }
        }
    }
    Context 'When a token is present in the Value' -Foreach @(
        @{
            StencilText = '${env.Greeting} ${env.Subject}'
            Expected = 'Hello World'
            Data = [PSCustomObject]@{
                PSTypeName = 'Stencil.JobInfo'
                env = @{
                    Greeting = 'Hello'
                    Subject  = 'World'
                }
            }
        }
        @{
            StencilText = '${env.Greeting} ${not.present} ${env.Subject}'
            Expected    = 'Hello ${not.present} World'
            Data        = [PSCustomObject]@{
                PSTypeName = 'Stencil.JobInfo'
                env = @{
                    Greeting = 'Hello'
                    Subject  = 'World'
                }
            }

        }
    ) {
        BeforeAll {
            $result = $StencilText | Expand-StencilValue -Data $Data
        }

        It "Should Replace the tokens in the text '<StencilText>'" {
            $result | Should -be $Expected
        }
    }
}
