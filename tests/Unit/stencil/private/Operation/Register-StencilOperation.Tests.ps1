[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

BeforeAll {
    $sourceFile = (Get-SourceFilePath $PSCommandPath)
    if (Test-Path $sourceFile) {
        . $sourceFile
    } else {
        throw "Could not find $sourceFile from $PSCommandPath"
    }

    $dataDirectory = (Get-TestDataPath $PSCommandPath)
}
Describe 'Private function Register-StencilOperation' -Tags @('unit', 'Register', 'StencilOperation') {
    BeforeAll {
        # convenience function to reset the registry
        function clearRegistry {
            $script:StencilOperationRegistry = @{}
        }

        function Get-StencilOperationRegistry {
            # false function so that Mock can find it
            return $null
        }
        Mock Get-StencilOperationRegistry {
            return $script:StencilOperationRegistry
        }
        function Test-StencilOperation {
            # false function so that Mock can find it
            return $null
        }
        Mock Test-StencilOperation {
            return $false
        }
    }
    Context 'The function is available from the module' {
        BeforeAll {
            $command = Get-Command 'Register-StencilOperation'
        }

        It 'Should load without error' {
            $command | Should -Not -BeNullOrEmpty
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
            $script:StencilOperationRegistry = @{
                test = @{
                    Command = { Write-Output 'Hello World'}
                    Description = 'A test task'
                }
            }
            $count_before = $script:StencilOperationRegistry.Keys.Count
            Register-StencilOperation -Name 'copy' -Command 'Copy-Item' -Description 'Copy Path to Destination'
        }

        AfterAll {
            clearRegistry
        }
        It 'Should increment the number of operations registered by 1' {
            $script:StencilOperationRegistry.Keys.Count | Should -Be ($count_before + 1)
        }

        It 'Should be added as a key in the registry by name' {
            $script:StencilOperationRegistry.Keys | Should -Contain 'copy'
        }

        Context 'If the name is already registered' {
            BeforeAll {
                Mock Test-StencilOperation {
                    return $true
                }

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
            $count_before = $script:StencilOperationRegistry.Keys.Count
            Register-StencilOperation -Name 'invoke' -Scriptblock {
                Write-Information 'Hello world'
            } -Description 'say hello'
        }
        It 'Should increment the number of operations registered by 1' {
            $script:StencilOperationRegistry.Keys.Count | Should -Be ($count_before + 1)
        }

        It 'Should be added as a key in the registry by name' {
            $script:StencilOperationRegistry.Keys | Should -Contain 'invoke'
        }
    }
}
