

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
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

Describe "Testing private function Convert-StringToToken" -Tags @('unit', 'StringToToken', 'Convert' ) {
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
    Context "When given the string '<Template>' to tokenize" -Foreach @(
        @{
            Template = 'This is a basic test'
            Count = 1
            Type = 'Text'
        }
    ) {
        BeforeAll {

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
            $tokens = Convert-StringToToken -Template $Template
        }
        It 'Then it should generate <Count> tokens' {
            $tokens.Count | Should -Be $Count
        }
    }
}
