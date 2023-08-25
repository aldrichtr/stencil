

Describe 'Testing the public function Get-Stencil' -Tag @('unit', 'public') {
    Context 'The command is available from the module' {
        BeforeAll {
            $command = Get-Command 'Get-Stencil'
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
    Context 'When a stencil file is given' {
        BeforeAll {
            $job_id = 'module_additional_folders'
            $job_name = 'Create additional folders'
            $stencil_dir = New-Item -ItemType Directory -Path 'TestDrive:\TestData'
            @"
name: 'Create directories'
version: 0.0.1

jobs:
  ${job_id}:
   name: $job_name
   steps:
    - tree:
       root: `${CurrentDir}
       docs:
        images:
"@ | Set-Content (Join-Path $stencil_dir 'stencil.yml')

            $stencils = Get-Stencil -Path $stencil_dir
        }
        It 'Should return one job' {
            $stencils.Count | Should -Be 1
        }

        It "Should have an Id of '$job_id'" {
            $stencils[0].Id | Should -Be $job_id
        }

        It "Should have a name of '$job_name'" {
            $stencils[0].Name | Should -Be $job_name
        }
    }

    Context 'When multiple jobs are given' {
        BeforeAll {
            $job1_id = 'module_additional_folders'
            $job1_name = 'Create additional folders'
            $job2_id = 'module_more_folders'
            $job2_name = 'Create even more folders'
            $stencil_dir = New-Item -ItemType Directory -Path 'TestDrive:\TestData'
            @"
name: 'Create directories'
version: 0.0.1

jobs:
  ${job1_id}:
   name: $job1_name
   steps:
    - tree:
       root: `${CurrentDir}
       docs:
        images:
  ${job2_id}:
   name: $job2_name
   scope: shared
   steps:
    - tree:
       root: `${CurrentDir}
       docs:
        images:
"@ | Set-Content (Join-Path $stencil_dir 'stencil.yml')
            Context 'When the -All parameter is not given' {
                BeforeAll {
                    $stencils = Get-Stencil -Path $stencil_dir
                }
                It 'Should return one job' {
                    $stencils.Count | Should -Be 1
                }

                It "Should have an Id of '$job1_id'" {
                    $stencils[0].Id | Should -Be $job1_id
                }

                It "Should have a name of '$job1_name'" {
                    $stencils[0].Name | Should -Be $job1_name
                }
            }
            Context 'When the -All parameter is not given' {
                BeforeAll {
                    $stencils = Get-Stencil -Path $stencil_dir -All
                }
                It 'Should return one job' {
                    $stencils.Count | Should -Be 2
                }

                It "The first job should have an Id of '$job1_id'" {
                    $stencils[0].Id | Should -Be $job1_id
                }

                It "The first job should have a name of '$job1_name'" {
                    $stencils[0].Name | Should -Be $job1_name
                }

                It "The second job should have an Id of '$job2_id'" {
                    $stencils[1].Id | Should -Be $job2_id
                }

                It "The second job should have a name of '$job2_name'" {
                    $stencils[1].Name | Should -Be $job2_name
                }
            }
        }
    }
}
