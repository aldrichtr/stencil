
function Convert-StringToToken {
    <#
    .SYNOPSIS
        Convert a String into a list of Tokens
    #>
    [Alias('Tokenize-Template')]
    [CmdletBinding()]
    param(
        # The template text to execute
        [Parameter(
            Mandatory
        )]
        [AllowEmptyString()]
        [string]$Template
    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"

        $config = Import-Configuration | Select-Object -ExpandProperty Template

        #-------------------------------------------------------------------------------
        #region Tag patterns

        $startTag, $endTag, $escapeChar = Get-TagStyle
        # literal escape tags
        $startTagPattern = ( -join ( '^', [regex]::Escape($startTag), '$' ))
        $endTagPattern = ( -join ( '^', [regex]::Escape($endTag), '$' ))

        $escapedStartPattern = ( -join ( '^', [regex]::Escape("$startTag$escapeChar"), '$' ))
        $escapedEndPattern = ( -join ( '^', [regex]::Escape("$escapeChar$endTag"), '$' ))

        $startTagWithPrefixPattern = ( -join ( '^', [regex]::Escape($startTag), '(?<prefix>\S+)' ))
        $endTagWithSuffixPattern = ( -join ( '(?<suffix>\S+)', [regex]::Escape($endTag), '$' ))

        #endregion Tag patterns
        #-------------------------------------------------------------------------------

        $lineEndingPattern = '\n$'

        # Options for creating a new Token
        $options = @{
            Type                = 'Text'
            Count               = 0
            # the spaces or tabs prior to the start tag
            Indent              = ''
            # The content is the "body" of the token
            Content             = ''
            # Zero-based index that the token starts at
            Start               = 0
            # I'm not sure the Length is required to be passed here because we can get it from the Content
            # but it is convenient for Substring
            Length              = 0
            # The prefix just after the start marker
            Prefix              = ''
            # The prefix just before the end marker
            Suffix              = ''
            # Any whitespace after the token
            RemainingWhiteSpace = ''
        }

        enum ReadState  {
            NONE
            TEXT
            START_TAG
        }

        #-------------------------------------------------------------------------------
        #region Split input
        $lines = $Template.Split($lineEndingPattern)
        $separator = ' '
        $buffer = $Template.Split($separator)
        #endregion Split input
        #-------------------------------------------------------------------------------

        #-------------------------------------------------------------------------------
        #region initialize tokenizer

        $cursor = 0
        $line = 0
        $startingCursor = 0

        $content = [System.Text.StringBuilder]::new()
        [ReadState]$state = NONE

        #endregion initialize tokenizer
        #-------------------------------------------------------------------------------
    }
    process {
        Write-Debug '- Looking for template tokens in content'
        :word foreach ($word in $buffer) {
            $index = $buffer.IndexOf($word)
            $nextWord = $buffer[($index + 1)]
            #TODO: Verify that the separator should be added to the front of the word
            # - for example, the first word will not have a space before it
            if ($cursor -eq 0) {
                $lexeme = "$separator$word"
            } else {
                $lexeme = "$word"
            }
            Write-Debug "${index}: Line: $line cursor $cursor - '$word'"
            :scan switch -Regex -CaseSensitive ($word) {
                $lineEndingPattern {
                    $line = $line + $Matches.Count
                    Write-Debug "LINES: Update line number to $line"
                    #! omit continue so that other patterns are processed
                }
                #TODO: I may just fold this into the prefix pattern and check for escape character
                $escapedStartPattern {
                    Write-Debug 'ESCAPED START - Add start tag to content'
                    [void]$content.Append("$separator$startTag")
                    continue scan
                }
                $startTagWithPrefixPattern {
                    :state switch ($state) {
                        START {
                            #TODO: Consider a custom exception to throw when nested tag found
                            throw "Error in template at line ${line}:`n$lines[$line]`nNested tags are not supported"
                        }
                        TEXT {
                            # End of a text block.  Create a token and reset
                            $options.Content = $content.ToString()
                            $options.Type = 'text'
                            $options.Start = $startingCursor
                            $startingCursor = $cursor
                            [void]$content.Clear()
                        }
                    }


                    $options.Prefix = $Matches.prefix
                    $startingCursor = $cursor
                    $state = START_TAG
                    continue scan
                }
                $startTagPattern {
                    $state = START_TAG
                    continue scan
                }

                $escapedEndPattern {
                    [void]$content.Append($lexeme)
                    continue scan
                }
                default {}
            }
            $cursor = $cursor + $lexeme.Length
        }

    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
