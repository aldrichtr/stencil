
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
        $startTagPattern = ( -join ( '^', [regex]::Escape($startTag), '(?<rightOf>\S+)?' ))
        $endTagPattern = ( -join ( '(?<leftOf>\S+)?', [regex]::Escape($endTag), '$' ))

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
        [ReadState]$state = [ReadState]::NONE

        #endregion initialize tokenizer
        #-------------------------------------------------------------------------------
    }
    process {
        Write-Debug '- Looking for template tokens in content'
        :word foreach ($word in $buffer) {
            $index = $buffer.IndexOf($word)
            $nextWord = $buffer[($index + 1)]
            #TODO: Add the space to the front of the word only if it is not the first word in the token
            if ($cursor -eq 0) {
                $lexeme = "$word"
            } else {
                $lexeme = (-join ($separator,$word))
            }
            Write-Debug "${index}: Line: $line cursor $cursor - '$word' lexeme '$lexeme'"
            :scan switch -Regex -CaseSensitive ($word) {
                $lineEndingPattern {
                    $line = $line + $Matches.Count
                    Write-Debug "LINES: Update line number to $line"
                    #! omit continue so that other patterns are processed
                }

                $startTagPattern {
                    Write-Debug "MATCH: Start tag ($startTagPattern)"
                    :startState switch ($state) {
                        ([ReadState]::START_TAG) {
                            #TODO: Consider a custom exception to throw when nested tag found
                            throw "Error in template at line ${line}:`n$lines[$line]`nNested tags are not supported"
                        }
                        ([ReadState]::NONE) {
                            #-------------------------------------------------------------------------------
                            #region Process prefix

                            $hasPrefix = $false
                            if ($null -ne $Matches.rightOf) {
                                $rightOfStartTag = $Matches.rightOf

                                if ($rightOfStartTag.Substring(0, 1) -eq $escapeChar) {
                                    Write-Debug 'ESCAPED START - Add start tag to content'
                                    # The first character is an escape character
                                    # add the start tag and the other characters from the prefix
                                    # so '<%%want_to_keep' becomes '<%want_to_keep'
                                    #! the cursor will be advanced based on lexeme
                                    $lexeme = ( -join (
                                            $separator,
                                        ($word -replace [regex]::Escape("startTag$escapeChar"))
                                        ))
                                    $content.Append( $lexeme )
                                    #! Don't go any further
                                    continue scan
                                } else {
                                    # The match is the prefix. Signal for inclusion
                                    $hasPrefix = $true
                                }
                            }
                            #endregion Process prefix
                            #-------------------------------------------------------------------------------
                            #-------------------------------------------------------------------------------
                            #region Reset

                            $startingCursor = $cursor

                            #endregion Reset
                            #-------------------------------------------------------------------------------

                            $state = [ReadState]::START_TAG
                            if ($hasPrefix) {
                                $options.Prefix = $rightOfStartTag
                            }
                            continue scan
                        }
                        ([ReadState]::TEXT) {
                            #TODO: I might be able to collapse NONE and TEXT together and use MoveNext
                            # - see
                            #   https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-switch?view=powershell-7.3#switch-automatic-variable
                            #   maybe move TEXT xefore NONE and just do the create new token part then MoveNext
                            #-------------------------------------------------------------------------------
                            #region Process prefix

                            $hasPrefix = $false
                            if ($null -ne $Matches.rightOf) {
                                $rightOfStartTag = $Matches.rightOf

                                if ($rightOfStartTag.Substring(0, 1) -eq $escapeChar) {
                                    Write-Debug 'ESCAPED START - Add start tag to content'
                                    # The first character is an escape character
                                    # add the start tag and the other characters from the prefix
                                    # so '<%%want_to_keep' becomes '<%want_to_keep'
                                    #! the cursor will be advanced based on lexeme
                                    $lexeme = ( -join (
                                            $separator,
                                        ($word -replace [regex]::Escape("$startTag$escapeChar"), $startTag)
                                        ))
                                    $content.Append( $lexeme )
                                    #! Don't go any further
                                    continue scan
                                } else {
                                    # The match is the prefix. Signal for inclusion
                                    $hasPrefix = $true
                                }
                            }
                            #endregion Process prefix
                            #-------------------------------------------------------------------------------

                            #-------------------------------------------------------------------------------
                            #region Create text token

                            $options.Content = $content.ToString()
                            $options.Type = 'text'
                            $options.Start = $startingCursor

                            New-TemplateToken @options
                            #endregion Create text token
                            #-------------------------------------------------------------------------------
                            #-------------------------------------------------------------------------------
                            #region Reset

                            $startingCursor = $cursor
                            [void]$content.Clear()

                            #endregion Reset
                            #-------------------------------------------------------------------------------

                            $state = [ReadState]::START_TAG
                            #TODO: Here we would process prefix and next word to determine the type
                            if ($hasPrefix) {
                                $options.Prefix = $rightOfStartTag
                            }
                            continue scan
                        }
                    } # end startState
                } # end start tag
                $endTagPattern {
                    Write-Debug "MATCH: End Tag ($endTagPattern)"
                    :endState switch ($state) {
                        ([ReadState]::NONE) {
                            # move to TEXT , same error
                            [void]$switch.MoveNext()
                        }
                        ([ReadState]::TEXT) {
                            #TODO: Consider a custom exception to throw when nested tag found
                            throw "Error in template at line ${line}:`n$lines[$line]`nEnd tag without start tag"
                        }
                        ([ReadState]::START_TAG) {
                            #-------------------------------------------------------------------------------
                            #region Process suffix

                            $hasSuffix = $false
                            if ($null -ne $Matches.leftOf) {
                                $leftOfEndTag = $Matches.leftOf

                                if ($leftOfEndTag.Substring(($leftOfEndTag.length - 1), 1) -eq $escapeChar) {
                                    Write-Debug 'ESCAPED END - Add end tag to content'
                                    # The last character is an escape character
                                    # add the end tag and the other characters from the suffix
                                    # so '<%%want_to_keep' becomes '<%want_to_keep'
                                    #! the cursor will be advanced based on lexeme
                                    $lexeme = ( -join (
                                            $separator,
                                        ($word -replace [regex]::Escape("$escapeChar$endTag"), $endTag)
                                        ))
                                    $content.Append( $lexeme )
                                    #! Don't go any further
                                    continue scan
                                } else {
                                    # The match is the prefix. Signal for inclusion
                                    $hasSuffix = $true
                                }
                            }
                            #endregion Process suffix
                            #-------------------------------------------------------------------------------

                            #-------------------------------------------------------------------------------
                            #region Create Expression

                            $options.Content = $content
                            #TODO: The type will actually depend on  what is in prefix and the first word
                            $options.Type = 'Expression'
                            $options.Start = $startingCursor
                            if ($hasSuffix) {
                                $options.Suffix = $leftOfEndTag
                            }
                            Write-Debug "Creating Token"
                            New-TemplateToken @options

                            #endregion Create Expression
                            #-------------------------------------------------------------------------------
                            #-------------------------------------------------------------------------------
                            #region Reset
                            #TODO: Set the cursor to the proper location
                            $startingCursor = $cursor
                            [void]$content.Clear()
                            #endregion Reset
                            #-------------------------------------------------------------------------------

                            #TODO: Is it ok to set the state to TEXT here?
                            Write-Debug "Setting state to TEXT"
                            $state = [ReadState]::TEXT
                            continue scan
                        }
                    } # end endState

                }
                default {
                    Write-Debug "MATCH: default"
                    switch ($state) {
                        ([ReadState]::NONE) {
                            $state = [ReadState]::TEXT
                        }
                    }
                    Write-Debug "Adding to content"
                    [void]$content.Append($lexeme)
                }
            } # end scan
            $cursor = $cursor + $lexeme.Length
        } # end foreach word

        # if there is still content
        Write-Debug "Reached End of input"
        if ($content.Length -gt 0) {
            Write-Debug ""
            switch ($state) {
                ([ReadState]::START_TAG) {
                    throw "Error in template. No closing tag found before end of input"
                }
                ([ReadState]::TEXT) {
                    $options.Type = 'text'
                    $options.Content = $content.ToString()
                    $options.Start = $startingCursor

                    New-TemplateToken @options

                    [void]$content.Clear()
                }
            }
        }

    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
