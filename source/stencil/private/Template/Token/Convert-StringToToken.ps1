
function Convert-StringToToken {
    <#
    .SYNOPSIS
        Convert a String into a list of Tokens
    .DESCRIPTION
    .EXAMPLE
        Convert-StringToToken $template
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
        #region ! regex patterns

        $startTag, $endTag, $escapeChar = Get-TagStyle
        # literal escape tags
        $startTagPattern = ( -join ( '^', [regex]::Escape($startTag), '(?<rightOf>\S+)?' ))
        $endTagPattern = ( -join ( '(?<leftOf>\S+)?', [regex]::Escape($endTag), '$' ))
        $whitespacePattern = [regex]::Escape($config.Whitespace)
        #endregion regex patterns
        #-------------------------------------------------------------------------------

        enum TokenState  {
            TEXT # Inside a Text block
            OPEN # Start tag found
            ELMT # Within an element
            CLOSE # End tag found
        }

        enum LineEndingType {
            LF # /n only
            CRLF # /r/n
        }
        Write-Debug "Template is $($Template.Length) characters"
        #-------------------------------------------------------------------------------
        #region ! Split input

        # Split input into lines
        $lines = $Template.Split("`n")
        Write-Debug "Template contains $($lines.Count) lines"

        # each line is split into "words"
        $separator = ([char]' ')

        #endregion Split input
        #-------------------------------------------------------------------------------

        #-------------------------------------------------------------------------------
        #region ! initialize tokenizer

        # keep track of our position in the input
        $cursor = $lineNumber = $column = 0

        # TODO: Add the level to the options
        # keep track of open and close tags
        $level = 0

        # keep track of "words" across the entire Template
        $totalWordCount = 0

        # Assume the line ending type is Unix
        $lineEnding = [LineEndingType]::LF

        # The current state of the cursor
        [TokenState]$state = [TokenState]::TEXT

        # Options for creating a new Token
        $options = @{
            Type                = 'Text'
            # Each time a Token is created the index is incremented
            Index               = 0
            # the whitespace (spaces or tabs) prior to the start tag
            Indent              = ''
            # The content is the "body" of the token
            Content             = [System.Text.StringBuilder]::new()
            # Position information for start of the token
            Start               = @{
                Index  = 0
                Line   = 0
                Column = 0
            }
            # Position information for end of the token
            End               = @{
                Index  = 0
                Line   = 0
                Column = 0
            }
            # The prefix just after the start marker
            Prefix              = ''
            # The prefix just before the end marker
            Suffix              = ''
            # Any whitespace after the token
            RemainingWhiteSpace = ''
            # Remove the Newline after the element
            RemoveNewLine       = $false
            # Remove the preceding whitespace
            RemoveIndent        = $false
        }

        #endregion initialize tokenizer
        #-------------------------------------------------------------------------------
    }
    process {
        Write-Verbose '- Tokenizing template'

        Set-StartPosition
        :line foreach ($line in $lines) {
            #-------------------------------------------------------------------------------
            #region ! foreach Line
            #-------------------------------------------------------------------------------
            #region Handle line endings

            $carriageReturn = $line.IndexOf("`r")
            if ( $carriageReturn -gt 0) {
                #TODO: Do we care if it at the end or not?
                $lineEnding = [LineEndingType]::CRLF
                Write-Debug "Remove Carriage Return mark at index $carriageReturn"
                $line = $line -replace '\r', ''
            } else {
                Write-Debug 'No Carriage Return found'
                $lineEnding = [LineEndingType]::LF
            }

            #endregion Handle line endings
            #-------------------------------------------------------------------------------
            Write-Debug ("$('=' * 35) Line {0:d3} $('=' * 36)" -f $lineNumber)
            Write-Debug "Current line: '$([regex]::Escape($line))'"


            if ([string]::IsNullOrEmpty($line)) {
                Write-Debug "- line $($lineNumber) is empty"
                if ($lineNumber -eq $lines.Length) {
                    Write-Debug '- Last line of input'
                    if ($options.Content.Length -gt 0) {
                        Write-Debug '- Add a newline to content'
                        switch ($lineEnding) {
                            ([LineEndingType]::CRLF) {
                                Write-Debug '- Add Carriage Return/Line Feed'
                                [void]$options.Content.Append("`r`n")
                            }
                            ([LineEndingType]::LF) {
                                Write-Debug '- Add Line Feed'
                                [void]$options.Content.Append("`n")
                            }
                        }
                        New-TemplateToken @options
                        Reset-TokenOption -IncludeContent
                    }
                    continue line
                }
            }

            #-------------------------------------------------------------------------------
            #region ! Initialize line

            # counter for words in the current line
            $wordIndex = 0
            # reset Column to start of line
            $column = 0

            #track the last word of the line
            $isLastWord = 0

            $words = $line.Split($separator)
            Write-Debug "Split line into $($words.Count) words"

            #endregion Initialize line
            #-------------------------------------------------------------------------------

            :word foreach ($word in $words) {
                #-------------------------------------------------------------------------------
                #region ! foreach Word
                if ($wordIndex -lt $words.Count) {
                    $nextWord = $words[($wordIndex + 1)]
                    $isLastWord = $false
                } else {
                    Write-Debug '- Last word in line'
                    $nextWord = $null
                    $isLastWord = $true
                }

                if ($options.Content.Length -eq 0) {
                    Write-Debug '- Content is empty'
                    $lexeme = "$word"
                } else {
                    Write-Debug '- There is content'
                    $lexeme = ( -join ($separator, $word))
                }
                Write-Debug "- Lexeme is [$lexeme]"

                (@(
                    "-- Scanning current word '$([regex]::Escape($word))' $('-' * 40)",
                    "| Counter - ($totalWordCount):",
                    "|- Index:     $($options.Index)",
                    "|- Line:      $lineNumber",
                    "|- Cursor:    $cursor",
                    "|- Column:    $column",
                    '|- ---',
                    "|- Start:    Line: $($options.Start.Line):$($options.Start.Column) - Index $($options.Start.Index)]",
                    "|- End:      Line: $($options.End.Line):$($options.End.Column) - Index $($options.End.Index)]",
                    '|- ---',
                    "|- Word index in this line: $wordIndex of $($words.Count)"
                    "|- Previous word:  [$prevWord]",
                    "|- Current word:   [$word] <---",
                    "|- Next word:      [$nextWord]",
                    '|- ---',
                    "|- State:     $state",
                    "|- Content:   [$($options.Content.ToString())]",
                    "|- Prefix:    [$($options.Prefix)]",
                    "|- Suffix:    [$($options.Suffix)]",
                    "$('-' * 49)"

                ) -join "`n") | Write-Debug

                :scan switch -Regex -CaseSensitive ($word) {

                    '^$' {
                        #-------------------------------------------------------------------------------
                        #region ! word is null
                        #TODO: What about tabs?
                        #TODO: Record any space after CLOSE for RemainingWhiteSpace
                        if ($isLastWord) {
                            Write-Debug 'This is the last word in the line'
                            #TODO: Do I add the newline here or at the end of the loop?
                        } else {
                            Write-Debug '| MATCH: Null - add a space to content'
                            [void]$options.Content.Append($separator)
                            if ($column -eq 0) {
                                Write-Debug '- space after newline (start indent)'
                                $options.Indent = 1
                            } elseif ($options.Indent -gt 0) {
                                $options.Indent++
                                Write-Debug "- Adding to indent. total indent: $($options.Indent)"
                            }
                        }

                        #endregion word is null
                        #-------------------------------------------------------------------------------
                    }
                    $startTagPattern {
                        #-------------------------------------------------------------------------------
                        #region ! word matches start tag

                        Write-Debug "| MATCH: Start tag ($startTag) regex ($startTagPattern)"
                        #-------------------------------------------------------------------------------
                        #region ! Process prefix
                        $hasPrefix = $false
                        if ($null -ne $Matches.rightOf) {
                            Write-Debug '- Characters found after start tag'
                            $rightOfStartTag = $Matches.rightOf

                            if ($rightOfStartTag.Substring(0, 1) -eq $escapeChar) {
                                #-------------------------------------------------------------------------------
                                #region ! Escaped Start

                                Write-Debug '** ESCAPED START - Add start tag to content'
                                # The first character is an escape character
                                # add the start tag and the other characters from the prefix
                                # so '<%%want_to_keep' becomes '<%want_to_keep'
                                #! Advance the cursor because we are going onto the next word
                                $lexeme = ( -join (
                                        $separator,
                                        ($word -replace [regex]::Escape("$escapeChar$endTag"), $endTag)
                                    ))
                                Write-Debug "  - Adding $lexeme to content"
                                [void]$options.Content.Append( $lexeme )
                                #TODO: What other counters need to be incremented if the start tag is escaped?
                                Update-Cursor
                                Update-Column
                                #! Move onto the next word
                                continue word

                                #endregion Escaped Start
                                #-------------------------------------------------------------------------------
                            } else {
                                Write-Debug 'Characters found are a Prefix'
                                # The match is the prefix. Signal for inclusion
                                $hasPrefix = $true
                                # increase the nest level
                                $level++
                            }
                        } else {
                            Write-Debug '-- No characters found after start tag'
                        }
                        #endregion Process prefix
                        #-------------------------------------------------------------------------------
                        Write-Debug "Check condition when state is $state"
                        :startState switch ($state) {
                            ([TokenState]::OPEN) {
                                Write-Debug '** Error Found start tag after start tag **'
                            }

                            ([TokenState]::ELMT) {
                                Write-Debug '** Error Found start tag in element'
                            }

                            default {
                                Write-Debug "At $($MyInvocation.ScriptName):$($MyInvocation.ScriptLineNumber)"
                                Write-Debug '- State matches default'
                                #-------------------------------------------------------------------------------
                                #region ! Create text token
                                if ($options.Content.Length -gt 0) {
                                    Write-Debug 'Content is not empty'

                                    <#
                                    I think what I need to do to get the positions right is:
                                    - Set options.End
                                    - Advance the cursor and counters
                                    - Set options.Start

                                    #>
                                    $options.Type = 'text'
                                    #! Set the current position before we advance past start tag
                                    Write-Debug "- Set End position"
                                    Set-EndPosition
                                    Write-Debug '**** Create Token ****'
                                    New-TemplateToken @options
                                    #-------------------------------------------------------------------------------
                                    #region ! Update
                                    Update-Cursor
                                    Update-Column
                                    Reset-TokenOption -IncludeContent
                                    Set-StartPosition
                                    #endregion Update
                                    #-------------------------------------------------------------------------------
                                } else {
                                    Write-Debug "Content is empty"
                                    # If the first word in the input is a start tag, there
                                    # wont be any input.  Set the Start position here and then update the position
                                    Set-StartPosition
                                    Update-Cursor
                                    Update-Column
                                    Reset-TokenOption
                                }
                                #endregion Create text token
                                #-------------------------------------------------------------------------------

                                Write-Debug "STATE CHANGE: $state -> OPEN"
                                $state = [TokenState]::OPEN
                                if ($hasPrefix) {
                                    #TODO: Here we would process prefix and next word to determine the type
                                    $options.Prefix = $rightOfStartTag
                                }
                                #! do not process any more scan conditions
                                continue scan
                            }
                        } # end startState

                        #endregion word matches start tag
                        #-------------------------------------------------------------------------------
                    } # end start tag
                    $endTagPattern {
                        #-------------------------------------------------------------------------------
                        #region ! word matches end tag

                        Write-Debug '| MATCH: End Tag'
                        #-------------------------------------------------------------------------------
                        #region ! Process suffix

                        $hasSuffix = $false
                        if ($null -ne $Matches.leftOf) {
                            Write-Debug '- Characters found before end tag'
                            $leftOfEndTag = $Matches.leftOf

                            if ($leftOfEndTag.Substring(($leftOfEndTag.length - 1), 1) -eq $escapeChar) {
                                Write-Debug 'ESCAPED END - Add end tag to content'
                                # The last character is an escape character
                                # add the end tag and the other characters from the suffix
                                # so 'want_to_keep%%>' becomes 'want_to_keep%>'

                                #! Advance the cursor because we are going onto the next word
                                $lexeme = ( -join (
                                        $separator,
                                        ($word -replace [regex]::Escape("$escapeChar$endTag"), $endTag)
                                    ))
                                Write-Debug "Adding $lexeme to content"
                                [void]$options.Content.Append( $lexeme )
                                Update-Cursor
                                Update-Column
                            } else {
                                Write-Debug 'Characters found are a Suffix'
                                # The match is the prefix. Signal for inclusion
                                $hasSuffix = $true
                                # decrement the nest level
                                $level--
                            }
                        } else {
                            Write-Debug '-- No characters found before end tag'
                        }
                        #endregion Process suffix
                        #-------------------------------------------------------------------------------
                        Write-Debug "Check condition when state is $state"
                        :endState switch ($state) {
                            ([TokenState]::CLOSE) {
                                Write-Debug '** Error Found end tag after end tag **'
                            }
                            ([TokenState]::TEXT) {
                                Write-Debug '** Error Found end tag without start tag'
                                #TODO: Unless we are closing multiple levels?
                            }
                            default {
                                #TODO: Process the Prefix, Suffix and keywords

                                #TODO: Here we want to "peek" at the rest of the line
                                #  to see if it is only whitespace
                                Write-Debug '- State matches default'
                                #-------------------------------------------------------------------------------
                                #region ! Create Expression

                                $options.Type = 'elmt'

                                if ($hasSuffix) {
                                    $options.Suffix = $leftOfEndTag
                                }
                                Set-EndPosition

                                Write-Debug '**** Create Token ****'
                                New-TemplateToken @options

                                #endregion Create Expression
                                #-------------------------------------------------------------------------------

                                #-------------------------------------------------------------------------------
                                #region ! Update
                                Write-Debug "- Advance the cursor and column by $($lexeme.Length)"
                                #TODO: Ensure we set the cursor to the proper location
                                Update-Cursor
                                Update-Column
                                Reset-TokenOption -IncludeContent
                                Set-StartPosition

                                Write-Debug "STATE CHANGE: $state -> CLOSE"
                                $state = [TokenState]::CLOSE

                                #continue scan
                                #endregion Update
                                #-------------------------------------------------------------------------------
                            }
                        } # end endState

                        #endregion word matches end tag
                        #-------------------------------------------------------------------------------
                    }
                    default {
                        #-------------------------------------------------------------------------------
                        #region ! word did not match
                        Write-Debug 'MATCH: default'
                        Write-Debug "Check condition when state is $state"
                        switch ($state) {
                            ([TokenState]::OPEN) {
                                #TODO: This is the first word after an open tag. Check for keyword
                                Write-Debug "STATE CHANGE: $state -> ELMT"
                                $state = [TokenState]::ELMT
                            }
                            ([TokenState]::CLOSE) {
                                Write-Debug "STATE CHANGE: $state -> TEXT"
                                $state = [TokenState]::TEXT
                            }
                        }
                        Write-Debug '- Adding to content'
                        [void]$options.Content.Append($lexeme)

                        #-------------------------------------------------------------------------------
                        #region ! Reset
                        Write-Debug '- Reset Indent'
                        $options.Indent = 0
                        #endregion Reset
                        #-------------------------------------------------------------------------------

                        #endregion word did not match
                        #-------------------------------------------------------------------------------
                    }
                } # end scan
                Write-Debug '- Store current word as prevWord'
                $prevWord = $word
                #-------------------------------------------------------------------------------
                #region ! Increment counters

                Write-Debug '- Increment word count'
                $wordIndex++
                $totalWordCount++

                #endregion Increment counters
                #-------------------------------------------------------------------------------
                (@(
                    "Finished scanning word [$word]"
                    "Word index in input - ($totalWordCount):",
                    "- Index:     $($options.Index)",
                    "- Line:      $lineNumber",
                    "- Cursor:    $cursor",
                    "- Column:    $column",
                    '- ---',
                    "- Word index in this line: $wordIndex"
                    "- Previous:  [$prevWord]",
                    "- Word:      [$word] <---",
                    "- Next:      [$nextWord]",
                    '- ---',
                    "- State:     $state",
                    "- Content:   [$($options.Content.ToString())]",
                    "- Prefix:    [$($options.Prefix)]",
                    "- Suffix:    [$($options.Suffix)]",
                    "$('-' * 40) End ---",
                    ''

                ) -join "`n") | Write-Debug

                #endregion foreach Word
                #-------------------------------------------------------------------------------
            }
            Write-Debug '- Add a newline to content'
            switch ($lineEnding) {
                ([LineEndingType]::CRLF) {
                    Write-Debug '- Add Carriage Return/Line Feed'
                    [void]$options.Content.Append("`r`n")
                }
                ([LineEndingType]::LF) {
                    Write-Debug '- Add Line Feed'
                    [void]$options.Content.Append("`n")
                }
            }
            Write-Debug "== End Line $('=' * 69)"
            if ($lineNumber -le $lines.Length) {
                Write-Debug 'increment linenumber'
                $lineNumber++
            }
            #endregion foreach Line
            #-------------------------------------------------------------------------------
        }

        #-------------------------------------------------------------------------------
        #region ! remaining content

        Write-Debug '** Reached End of input **'
        if ($options.Content.Length -gt 0) {
            Write-Debug '- There is remaining content'
            Write-Debug "Check condition when state is $state"
            switch ($state) {
                ([TokenState]::OPEN) {
                    Write-Debug 'Error No closing tag found before end of input'
                }
                ([TokenState]::ELMT) {
                    Write-Debug 'Error end of input while in Element'
                }

                default {
                    Write-Debug '- default'
                    $options.Type = 'text'

                    Set-EndPosition
                    Write-Debug '**** Create Token ****'
                    New-TemplateToken @options
                    Reset-TokenOption -IncludeContent
                }
            }
        }

        #endregion remaining content
        #-------------------------------------------------------------------------------
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
