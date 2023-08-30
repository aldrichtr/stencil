

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

BeforeAll {
    $dependencies = 'Reset-TokenOption'
    $sourceFile = (Get-SourceFilePath $PSCommandPath)
    if (Test-Path $sourceFile) {
        . $sourceFile
    } else {
        throw "Could not find $sourceFile from $PSCommandPath"
    }

    $dependencies
    | Resolve-Dependency
    | ForEach-Object { . $_ }

    $dataDirectory = (Get-TestDataPath $PSCommandPath)
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
    Context "When given the string '<Template>' to tokenize" -ForEach @(
        @{
            Template = 'This is a basic test'
            Count    = 1
            Tokens   = @(
                @{
                    Type       = 'Text'
                    Content    = 'This is a basic test'
                    Start      = 0
                    Number     = 0
                    LineNumber = 0
                }
            )
        }
        @{
            Template = 'This is a basic test <% this is an element %>'
            Count    = 2
            Tokens   = @(
                @{
                    Type       = 'Text'
                    Content    = 'This is a basic test'
                    Start      = 0
                    Number     = 0
                    LineNumber = 0
                }
                @{
                    Type       = 'Expression'
                    Content    = 'This is an element'
                    Start      = 21
                    Number     = 1
                    LineNumber = 0
                }
            )
        }
        @{
            #           0    5    10   15   20   25   30   35   40
            #           |    |    |    |    |    |    |    |    |
            Template = '<% this is an element %> This is a basic test'
            Count    = 2
            Tokens   = @(
                @{
                    Type       = 'Expression'
                    Content    = 'This is an element'
                    Start      = 0
                    Number     = 1
                    LineNumber = 0
                }
                @{
                    Type       = 'Text'
                    Content    = 'This is a basic test'
                    Start      = 24
                    Number     = 0
                    LineNumber = 0
                }
            )
        }
    ) {
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

            function New-TemplateToken {}
            Mock New-TemplateToken {
                $tokenInfo = @{}
                for ($i = 0; $i -lt $args.Length; $i++ ) {
                    if ($args[$i].Substring(0, 1) -eq '-') {
                        $key = ($args[$i] -replace '-', '' -replace ':', '')
                        $value = $args[++$i]
                        if (-not ([string]::IsNullorEmpty($value))) {
                            $tokenInfo[$key] = $value
                        }
                    }
                }
                $tokenInfo['PSTypeName'] = 'Stencil.MockToken'
                $token = [PSCustomObject]$tokenInfo
                return ($token)
            }

            #endregion Mock functions
            #-------------------------------------------------------------------------------
            $tokens = Convert-StringToToken -Template $Template
        }

        It 'Then it should generate <Count> tokens' {
            $tokens.Count | Should -Be $Count
        }

        Context 'And Then for token number <Number>' -ForEach $Tokens {

            It 'It should be number <Number>' {
                $_.Number | Should -Be $Number
            }
            It 'It should be on line <LineNumber>' {
                $_.LineNumber | Should -Be $LineNumber
            }
            It 'It should be of type <Type>' {
                $_.Type | Should -BeLike $Type
            }

            It 'It should have content like <Content>' {
                $_.Content | Should -BeLike $Content
            }

            It 'It should start at position <Start>' {
                $_.Start | Should -Be $Start
            }
        }
    }
}
