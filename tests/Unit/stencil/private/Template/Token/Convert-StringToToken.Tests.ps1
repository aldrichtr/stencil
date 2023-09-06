

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

BeforeAll {
    #! I know that each test should isolate the function to be tested, but in this case
    #! The functions are very tightly coupled and help reduce complexity in `Convert-StringToToken`
    $dependencies = @(
        'Reset-TokenOption',
        'New-TemplateToken',
        'Update-Cursor',
        'Update-Column',
        'Set-StartPosition',
        'Set-EndPosition'
    )

    $sourceFile = Get-SourceFilePath
    if (-not ([string]::IsNullorEmpty($sourceFile))) {
        if (Test-Path $sourceFile) {
            . $sourceFile
        } else {
            throw "Could not find $sourceFile from $PSCommandPath"
        }
    } else {
        throw "$PSCommandPath did not find a source file"
    }

    $dependencies
    | Resolve-Dependency
    | ForEach-Object { . $_ }

    $dataDirectory = Get-TestDataPath
}


BeforeDiscovery {
    $templateTestData = [System.Collections.ArrayList]@()

    Get-TestData -Filter { $_.Extension -like '.pst1' }
    | ForEach-Object {
        $testDataFile = ($_.FullName -replace '\.template\.pst1$', '.data.psd1')
        $testData = Import-Psd $testDataFile
        if ($null -ne $testData) {
            if ($testData.Enabled) {
                $testData['FileName'] = $_.Name
                $testData['Template'] = (Get-Content $_ -Raw)
                [void]$templateTestData.Add($testData)
            } else {
                Write-Host "$($_.Name) is disabled"
            }
        } else {
            throw "Could not import $testDataFile"
        }
    }

    if ($templateTestData.Count -eq 0) {
        throw 'Could not Import test data'
    } else {
        Write-Host "Template Test Data contains $($templateTestData.Count) tests"
    }
}

Describe 'Testing private function Convert-StringToToken' -Tags @('unit', 'StringToToken', 'Convert' ) {
    Context 'The Convert-StringToToken command is available and is valid' {
        BeforeAll {
            $command = Get-Command 'Convert-StringToToken'
            $tokens, $errors = @()
            $parsed = [System.Management.Automation.Language.Parser]::ParseFile($sourceFile, [ref]$tokens, [ref]$errors)

        }

        It 'The source file should exist' {
            $sourceFile | Should -Exist
        }

        It 'It should be a valid command' {
            $command | Should -Not -BeNullOrEmpty
        }

        It 'Should parse without error' {
            $errors.count | Should -Be 0
        }

        It "It Should have a 'Template' parameter" {
            $command.Parameters['Template'].Attributes.Mandatory | Should -BeTrue
        }

    }
    Context "When given the string '<Template>' to tokenize" -ForEach $templateTestData {
        BeforeAll {

            #-------------------------------------------------------------------------------
            #region Mock functions
            function Get-TagStyle {}

            Mock Get-TagStyle {
                return @('<%', '%>', '%')
            }
            function Import-Configuration {}
            Mock Import-Configuration {
                return @{
                    Template = @{
                        TagStyle    = 'default'

                        TagStyleMap = @{
                            default = @('<%', '%>', '%')
                        }

                        Whitespace  = '~'
                    }
                }
            }

            #endregion Mock functions
            #-------------------------------------------------------------------------------

            $results = Convert-StringToToken -Template $Template -Debug 5>debug.log
        }

        It 'Then it should generate <Count> tokens' {
            $results.Count | Should -Be $Count
        }

        Context 'And Then for token at index <Index>' -ForEach $Tokens {

            It 'It should be index <Index>' {
                $results[$Index].Index | Should -Be $Index
            }
            It 'It should be of type <Type>' {
                $results[$Index].Type | Should -BeLike $Type
            }

            It 'It should start at Position <Start.Index> - <Start.Line>:<Start.Column>' {
                $results[$Index].Start.Index | Should -Be $Start.Index
                $results[$Index].Start.Line | Should -Be $Start.Line
                $results[$Index].Start.Column | Should -Be $Start.Column
            }
            It 'It should end at Position <End.Index> - <End.Line>:<End.Column>' {
                $results[$Index].End.Index | Should -Be $End.Index
                $results[$Index].End.Line | Should -Be $End.Line
                $results[$Index].End.Column | Should -Be $End.Column
            }

            It 'It should have a Prefix like <Prefix>' {
                $results[$Index].Prefix | Should -Be $Prefix
            }
            It 'It should have an Indent like <Indent>' {
                $results[$Index].Indent | Should -Be $Indent
            }

            It 'It should have content like <Content>' {
                $results[$Index].Content | Should -BeLike $Content
            }

            It 'It should have RemainingWhitespace like <RemainingWhitespace>' {
                $results[$Index].RemainingWhitespace | Should -Be $RemainingWhitespace
            }

            It 'It should have a Suffix like <Suffix>' {
                $results[$Index].Suffix | Should -Be $Suffix
            }

            It 'It should set RemoveIndent <RemoveIndent>' {
                $results[$Index].RemoveIndent | Should -Be $RemoveIndent
            }
            It 'It should set RemoveNewLine <RemoveNewLine>' {
                $results[$Index].RemoveNewLine | Should -Be $RemoveNewLine
            }
        }
    }
}
