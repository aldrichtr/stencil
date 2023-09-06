
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
            End                 = @{
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
            Write-Debug '-- {{{ -Line------------------------------------------------------------------------------'
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
                Write-Debug "MATCH  line $($lineNumber) is empty"
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
                Write-Debug '-- {{{ -Word------------------------------------------------------------------------------'
                #-------------------------------------------------------------------------------
                #region ! foreach Word
                if ($wordIndex -lt ($words.Count - 1)) {
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

                Write-Debug "-- Scanning current word '$([regex]::Escape($word))' $('-' * 40)"

                # Output the line and a position marker below it
                Write-Debug "| $line"
                if ($column -gt 0) {
                    Write-Debug "| $('-' * ($column - 1))^"
                } else {
                    Write-Debug '| ^'

                }

                (@(
                    '-- {{{ --'
                    "| This is word ($totalWordCount) scanned so far",
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
                    '-- }}} --'
                    "$('-' * 49)"

                ) -join "`n") | Write-Debug

                :scan switch -Regex -CaseSensitive ($word) {

                    '^$' {
                        Write-Debug '-- {{{ SCAN: Null ---------------------------------------------------------------'
                        #-------------------------------------------------------------------------------
                        #region ! word is null
                        #TODO: Record any space after CLOSE for RemainingWhiteSpace
                        if ($isLastWord) {
                            Write-Debug 'This is the last word in the line'
                            #TODO: Do I add the newline here or at the end of the loop?
                        } else {
                            Write-Debug '| MATCH: Null - add a space to content'
                            [void]$options.Content.Append($separator)
                            if ($column -eq 0) {
                                Write-Debug '- space after newline (start indent)'
                                $options.Indent = ' '
                            } elseif ($options.Indent.Length -gt 0) {
                                $options.Indent += ' '
                                Write-Debug "- Adding to indent. total indent: '$($options.Indent)'"
                            }
                        }

                        #endregion word is null
                        #-------------------------------------------------------------------------------

                        Write-Debug '-------------------------------------------------------------------------}}} --'
                    }
                    '\t' {
                        Write-Debug '-- {{{ SCAN: tab ---------------------------------------------------------------'
                        if ($column -eq 0) {
                            Write-Debug '- tab after newline (start indent)'
                            $options.Indent = "`t"
                        } elseif ($options.Indent.Length -gt 0) {
                            $options.Indent += "`t"
                            Write-Debug "- Adding to indent. total indent: '$($options.Indent)'"
                        }

                        Write-Debug '-------------------------------------------------------------------------}}} --'
                    }
                    $startTagPattern {
                        #-------------------------------------------------------------------------------
                        #region ! word matches start tag
                        Write-Debug '-- {{{ SCAN: Start tag  ---------------------------------------------------------------'

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
                                Write-Debug 'Characters found is a Prefix'
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
                        :starttag switch ($state) {
                            ([TokenState]::OPEN) {
                                Write-Debug '** Error Found start tag after start tag **'
                            }

                            ([TokenState]::ELMT) {
                                Write-Debug '** Error Found start tag in element'
                            }

                            default {
                                Write-Debug '-- {{{ START TAG :: default ---------------------------------------------------------------'
                                <#
                                    If there is already content recorded, then that token needs to be created.
                                    - The End position should be the character just before the first character of
                                      the start tag.
                                #>
                                if ($options.Content.Length -gt 0) {
                                    Write-Debug 'There is content from the previous block'

                                    $options.Type = 'text'
                                    #! Set the current position before we advance past start tag
                                    Write-Debug '- Set End position for the previous content before advancing'
                                    Set-EndPosition
                                    New-TemplateToken @options
                                    Update-Cursor
                                    Update-Column
                                    Reset-TokenOption -IncludeContent
                                    Set-StartPosition

                                } else {
                                    Write-Debug 'Content is empty'
                                    # If the first word in the input is a start tag, there
                                    # wont be any input.  Set the Start position here and then update the position
                                    Set-StartPosition
                                    Update-Cursor
                                    Update-Column
                                    Reset-TokenOption
                                }

                                Write-Debug "STATE CHANGE: $state -> OPEN"
                                $state = [TokenState]::OPEN
                                if ($hasPrefix) {
                                    #TODO: Here we would process prefix and next word to determine the type
                                    $options.Prefix = $rightOfStartTag
                                }
                                #! do not process any more scan conditions
                                continue scan

                                Write-Debug '-------------------------------------------------------------------------}}} --'
                            }
                        } # end startState

                        Write-Debug '-------------------------------------------------------------------------}}} --'
                        #endregion word matches start tag
                        #-------------------------------------------------------------------------------
                    } # end start tag
                    $endTagPattern {
                        Write-Debug '-- {{{ SCAN: End Tag ---------------------------------------------------------'
                        #-------------------------------------------------------------------------------
                        #region ! word matches end tag

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
                                Write-Debug "- Adding $lexeme to content"
                                [void]$options.Content.Append( $lexeme )
                                Update-Cursor
                                Update-Column
                            } else {
                                Write-Debug 'Characters found is a Suffix'
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
                        :endtag switch ($state) {
                            ([TokenState]::CLOSE) {
                                Write-Debug '** Error Found end tag after end tag **'
                            }
                            ([TokenState]::TEXT) {
                                Write-Debug '** Error Found end tag without start tag'
                                #TODO: Unless we are closing multiple levels?
                            }
                            default {
                                Write-Debug '-- {{{ END TAG :: default ---------------------------------------------------------------'
                                #TODO: Process the Prefix, Suffix and keywords

                                #-------------------------------------------------------------------------------
                                #region ! Create Expression

                                $options.Type = 'elmt'

                                if ($hasSuffix) {
                                    $options.Suffix = $leftOfEndTag
                                }
                                Write-Debug "- Advance the cursor and column by $($lexeme.Length) to the end of the end tag"
                                Update-Cursor
                                Update-Column
                                #TODO: Here we want to "peek" at the rest of the line
                                #  to see if it is only whitespace

                                if ($isLastWord) {
                                    Write-Debug "'$word' is the last word in line $lineNumber"
                                } else {
                                    $from = ($wordIndex + 1)
                                    $to = ($words.Count - 1)
                                    $remainingWords = ($line[$from..$to] -join $separator)
                                    Write-Debug "Remaining words on this line are '$remainingWords'"
                                }

                                Set-EndPosition

                                Write-Debug '**** Create Token ****'
                                New-TemplateToken @options

                                #endregion Create Expression
                                #-------------------------------------------------------------------------------

                                #-------------------------------------------------------------------------------
                                #region ! Update
                                Reset-TokenOption -IncludeContent
                                Set-StartPosition
                                Write-Debug "STATE CHANGE: $state -> CLOSE"
                                $state = [TokenState]::CLOSE


                                Write-Debug '-------------------------------------------------------------------------}}} --'
                                #endregion Update
                                #-------------------------------------------------------------------------------
                            }
                        } # end endState
                        Write-Debug '----------------------------------------------------------------------- }}} --'

                        #endregion word matches end tag
                        #-------------------------------------------------------------------------------
                    }
                    default {
                        Write-Debug '-- {{{ SCAN: default ---------------------------------------------------------'
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
                                Set-StartPosition
                            }
                        }
                        Write-Debug '- Adding to content'
                        Update-Cursor
                        Update-Column
                        [void]$options.Content.Append($lexeme)

                        #-------------------------------------------------------------------------------
                        #region ! Reset
                        Write-Debug '- Reset Indent'
                        $options.Indent = ''
                        #endregion Reset
                        #-------------------------------------------------------------------------------

                        #endregion word did not match
                        #-------------------------------------------------------------------------------
                        Write-Debug '----------------------------------------------------------------------- }}} --'
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
                    "$('-' * 40) End ---",
                    ''

                ) -join "`n") | Write-Debug

                #endregion foreach Word
                #-------------------------------------------------------------------------------
                Write-Debug '------------------------------------------------------------------------------- }}} --'
            }
            Write-Debug 'END OF LINE'
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
            Write-Debug '----------------------------------------------------------------------------------- }}} --'
            if ($lineNumber -le $lines.Length) {
                Write-Debug 'increment linenumber'
                $lineNumber++
            }
            #endregion foreach Line
            #-------------------------------------------------------------------------------
        }

        #-------------------------------------------------------------------------------
        #region ! remaining content

        Write-Debug 'END OF INPUT'
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
        } else {
            Write-Debug '- There is no remaining content'
        }

        #endregion remaining content
        #-------------------------------------------------------------------------------
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
