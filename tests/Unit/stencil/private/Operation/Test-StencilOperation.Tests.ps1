[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

BeforeAll {
    $sourceFile = Get-SourceFilePath
    if (Test-Path $sourceFile) {
        . $sourceFile
    } else {
        throw "Could not find $sourceFile from $PSCommandPath"
    }

    $dataDirectory = Get-TestDataPath
}
Describe 'Testing the private function Test-StencilOperation' -Tag @('unit', 'private') {
    Context 'The command is available from the module' {
        BeforeAll {
            $command = Get-Command 'Test-StencilOperation'
        }

        It 'Should load without error' {
            $command | Should -Not -BeNullOrEmpty
        }
    }
    Context "When the 'copy' operation is registered" -ForEach @(
        @{
            Name  = 'copy'
            Value = $true
        }
        @{
            Name  = 'new'
            Value = $false
        }
    ) {
        BeforeAll {
            $script:StencilOperationRegistry = @{
                copy = @{
                    Command     = { Write-Output 'Hello World' }
                    Description = 'A test copy operation'
                }
            }
        }

        It 'Should return <Value> when the <Name> operation is tested' {
            Test-StencilOperation $Name | Should -Be $Value
        }
    }
}
