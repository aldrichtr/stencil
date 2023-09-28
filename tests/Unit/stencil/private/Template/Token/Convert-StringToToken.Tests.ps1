

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

BeforeAll {
    #! I know that each test should isolate the function to be tested, but in this case
    #! The functions are very tightly coupled and help reduce complexity in `Convert-StringToToken`
    $dependencies = @(
        'Reset-TokenOption',
        'New-TemplateToken',
        'New-TextToken',
        'New-CommentToken',
        'Move-Position',
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
                $content = (Get-Content $_ -Raw)
                $testData['Template'] = $content
                $testData['Display'] = [regex]::Escape($content)
                [void]$templateTestData.Add($testData)
            } else {
                Write-Information "$($_.Name) is disabled"
            }
        } else {
            throw "Could not import $testDataFile"
        }
    }

    if ($templateTestData.Count -eq 0) {
        throw 'Could not Import test data'
    } else {
        Write-Information "Template Test Data contains $($templateTestData.Count) tests"
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
    Context "When given the string '<Display>' in file <FileName> to tokenize" -ForEach $templateTestData {
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

            $results = Convert-StringToToken -Template $Template #-Debug 5> "$FileName-debug.log"
        }

        It 'Then it should generate <Count> tokens' {
            $results.Count | Should -Be $Count
        }

        Context 'And Then for token at index <Index>' -ForEach $Tokens {
            BeforeAll {
                $result = $results[$Index]
            }

            It 'It should be the base token type Stencil.Template.Token' {
                $result.PSTypeNames | Should -Contain 'Stencil.Template.Token'
            }

            It 'It should be index <Index>' {
                $result.Index | Should -Be $Index
            }
            It 'It should be of type <Type>' {
                $result.Type | Should -BeLike $Type
            }

            It 'It should start at Index <Start.Index>' {
                $result.Start.Index | Should -Be $Start.Index
            }
            It 'It should start at Line <Start.Line>' {
                $result.Start.Line | Should -Be $Start.Line
            }
            It 'It should start at Column <Start.Column>' {
                $result.Start.Column | Should -Be $Start.Column
            }
            It 'It should end at Index <End.Index>' {
                $result.End.Index | Should -Be $End.Index
            }
            It 'It should end at Line <End.Line>' {
                $result.End.Line | Should -Be $End.Line
            }
            It 'It should end at Column <End.Column>' {
                $result.End.Column | Should -Be $End.Column
            }

            It 'It should have a Prefix like <Prefix>' {
                $result.Prefix | Should -Be $Prefix
            }
            It 'It should have an Indent like <Indent>' {
                $result.Indent | Should -Be $Indent
            }

            It "It should have content like [$([regex]::Escape($Content))]" {
                $result.Content | Should -BeLike $Content -Because ( -join (
                        "`n-",
                        "Results:  [$([regex]::escape($result.Content))]",
                        "Expected: [$([regex]::escape($Content))]"
                    ))
            }

            #TODO: Test that the content is the same as it is in the Template
            # - Get Start.Index and End.Index and then compare $content to $Template[$start..$end]
            It 'It should have RemainingWhitespace like <RemainingWhitespace>' {
                $result.RemainingWhitespace | Should -Be $RemainingWhitespace
            }

            It 'It should have a Suffix like <Suffix>' {
                $result.Suffix | Should -Be $Suffix
            }

            It 'It should set RemoveIndent <RemoveIndent>' {
                $result.RemoveIndent | Should -Be $RemoveIndent
            }
            It 'It should set RemoveNewLine <RemoveNewLine>' {
                $result.RemoveNewLine | Should -Be $RemoveNewLine
            }
        }
    }
}
