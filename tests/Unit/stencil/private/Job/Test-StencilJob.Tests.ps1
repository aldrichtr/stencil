[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

BeforeAll {
    $sourceFile = Get-SourceFilePath
    if (Test-Path $sourceFile) {
        . $sourceFile
    } else {
        throw "Could not find $sourceFile from $PSCommandPath"
    }

    $dataDirectory = (Get-TestDataPath $PSCommandPath)
}
Describe 'Testing the private function Test-StencilJob' -Tag @('unit', 'private') {
    Context 'The command is available from the module' {
        BeforeAll {
            $command = Get-Command 'Test-StencilJob'
        }

        It 'Should load without error' {
            $command | Should -Not -BeNullOrEmpty
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
            $script:Jobs = @(
                [PSCustomObject]@{
                    PSTypeName = 'Stencil.JobInfo'
                    Id         = 'test_job1'
                }
            )
        }

        It 'Should return <Value> when <Name> is tested' {
            Test-StencilJob $Name | Should -Be $Value
        }
    }

}
