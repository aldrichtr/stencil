
Describe 'Private function Register-StencilOperation' {
    BeforeAll {
        # convenience function to reset the registry
        function clearRegistry {
            $script:StencilOperationRegistry = @{}
        }
    }
    Context 'The function is available from the module' {
        BeforeAll {
            $command = Get-Command 'Register-StencilOperation'
        }

        It 'Should load without error' {
            $command | Should -Not -BeNullOrEmpty
        }

        It "Should pass PSScriptAnalyzer Rule '<_.RuleName>'" -Tag @('analyzer') -ForEach @(Get-ScriptAnalyzerRule) {
            $result = Invoke-ScriptAnalyzer -ScriptDefinition $command.Definition -IncludeRule $_.RuleName
            $result | Should -BeNullOrEmpty -Because (
                ".`n$($PSStyle.Foreground.BrightWhite){0} on line {1} {2}`n`n.$($PSStyle.Reset)" -f $result.Severity, $result.Line, $result.Message )
        }
        Context 'The parameters are set correctly' -ForEach @(
            @{
                Name      = 'Name'
                Mandatory = $true
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
    Context 'When a command operation is registered' {
        BeforeAll {
            $count_before = (Get-StencilOperationRegistry).Keys.Count
            Register-StencilOperation -Name 'copy' -Command 'Copy-Item' -Description 'Copy Path to Destination'
        }

        AfterAll {
            clearRegistry
        }
        It 'Should increment the number of operations registered by 1' {
            (Get-StencilOperationRegistry).Keys.Count | Should -Be ($count_before + 1)
        }

        It 'Should be added as a key in the registry by name' {
            $registry = Get-StencilOperationRegistry
            $registry.Keys | Should -Contain 'copy'
        }

        Context 'If the name is already registered' {
            BeforeAll {
                $options = @{
                    Name          = 'copy'
                    Command       = 'Copy-Item'
                    Description   = 'Copy Path to Destination'
                    ErrorAction   = 'Stop'
                }
                try {
                    Register-StencilOperation @options
                } catch {
                    $RegisterError = $_
                }
            }

            It "Should be a 'ResourceExists' error" {
                $RegisterError.CategoryInfo.Category | Should -Be ResourceExists
            }

            It 'Should state that the command could not be registered' {
                $RegisterError.Exception.Message | Should -Be (
                    "Could not register '$($options.Name)'"
                )
            }

        }
    }

    Context 'When a scriptblock operation is registered' {
        BeforeAll {
            $count_before = (Get-StencilOperationRegistry).Keys.Count
            Register-StencilOperation -Name 'invoke' -Scriptblock {
                Write-Information 'Hello world'
            } -Description 'say hello'
        }
        It 'Should increment the number of operations registered by 1' {
            (Get-StencilOperationRegistry).Keys.Count | Should -Be ($count_before + 1)
        }

        It 'Should be added as a key in the registry by name' {
            $registry = Get-StencilOperationRegistry
            $registry.Keys | Should -Contain 'invoke'
        }
    }
}
