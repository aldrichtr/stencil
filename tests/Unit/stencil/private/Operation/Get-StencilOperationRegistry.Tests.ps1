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
Describe 'Private function Get-StencilOperationRegistry' -Tag @('unit', 'private') {
    Context 'The command is available from the module' {
        BeforeAll {
            $command = Get-Command 'Get-StencilOperationRegistry'
        }
        It 'Should load without error' {
            $command | Should -Not -BeNullOrEmpty
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
