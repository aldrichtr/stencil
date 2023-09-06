
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

        function Write-Position {
            Write-Debug "+-- {{{ -Column ($column)--------------------------------------"
            Write-Debug '|- 0    5   10    15   20   25   30   35   40   45   50   55'
            Write-Debug '|- |....|....|....|....|....|....|....|....|....|....|....|'
            Write-Debug "|  $line"
            if ($column -gt 0) {
                Write-Debug "|  $('-' * ($column - 1))^"
            } else {
                Write-Debug '|  ^'
            }
            Write-Debug '+------------------------------------------------------ }}} --'

        }

        $startTag, $endTag, $escapeChar = Get-TagStyle
        #-------------------------------------------------------------------------------
        #region ! regex patterns
        $startTagPattern = ( -join (
                '^',
                [regex]::Escape($startTag),
                '(?<rightOf>\S+)?'
            ))
        $endTagPattern = ( -join (
                '(?<leftOf>\S+)?',
                [regex]::Escape($endTag),
                '$'
            ))
        #TODO: Make the whitespace removal marker configurable
        # $whitespaceMarkerPattern = [regex]::Escape($config.Whitespace)

        $indentPattern = ( -join (
                '^(?<indent>[ \t]+)',
                [regex]::Escape($startTag)
            ))
        $remainingWSPattern = ( -join (
                [regex]::Escape($endTag),
                '(?<remain>[ \t]+)$'
            ))
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
        $newline = [char]"`n"
        $return = [char]"`r"
        $separator = [char]' '
        $lines = [System.Collections.ArrayList]::new($Template.Split($newline))
        $lastLine = $lines[($lines.Count - 1)]
        if ($null -eq $lastLine) {
            Write-Debug "Removing extra line at file end"
            [void]$lines.RemoveAt( ($lines.Count - 1) )
        }
        Write-Debug "Template contains $($lines.Count) lines"

        # each line is split into "words"

        #endregion Split input
        #-------------------------------------------------------------------------------

        #-------------------------------------------------------------------------------
        #region ! initialize tokenizer

        # keep track of our position in the input
        $cursor = 0
        $column = 0

        $lineNumber = -1


        # TODO: Add the level to the options
        # keep track of open and close tags
        $level = 0

        # keep track of "words" across the entire Template
        $totalWordCount = -1

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
            $lineNumber++

            #region Handle line endings

            $carriageReturn = $line.IndexOf($return)
            if ( $carriageReturn -gt 0) {
                #TODO: Do we care if it at the end or not?
                $lineEnding = [LineEndingType]::CRLF
                Write-Debug "Remove Carriage Return mark at index $carriageReturn"
                $line = $line -replace [regex]::Escape($return), ''
            } else {
                Write-Debug 'No Carriage Return found'
                $lineEnding = [LineEndingType]::LF
            }

            #endregion Handle line endings
            #-------------------------------------------------------------------------------
            Write-Debug ("$('=' * 35) Line {0:d3} $('=' * 36)" -f $lineNumber)
            Write-Debug "Current line: '$([regex]::Escape($line))'"
            #-------------------------------------------------------------------------------
            #region Handle whitespace

            if ($line -match $indentPattern) {
                switch ($state) {
                    default {
                        Write-Debug '-- {{{ Indent :: default --'
                        $indent = $Matches.indent
                        Write-Debug '-- }}} --'
                    }
                }
            } else {
                $indent = $null
            }
            if ($line -match $remainingWSPattern) {
                switch ($state) {
                    default {
                        Write-Debug '-- {{{ Remaining :: default --'
                        $remainingWhiteSpace = $Matches.remain
                        Write-Debug '-- }}} --'
                    }
                }
            } else {
                $remain = $null
            }

            #endregion Handle whitespace
            #-------------------------------------------------------------------------------

            #-------------------------------------------------------------------------------
            #region ! Initialize line

            # reset Column to start of line
            $column = 0

            # counter for words in the current line
            $wordIndex = -1

            # track the last word of the line
            $isLastWord = $false

            # track the first word of the line
            $isFirstWord = $false


            if ($null -ne $indent) {
                Write-Debug 'Removing indent from line'
                $line = ( -join ( $line[($indent.Length - 1)..($line.Length - 1)]))
                Write-Debug "line is now [[regex]::Escape($line)]"
                $column = ($indent.Length - 1)
                $cursor = ($cursor + ($indent.Length - 1))
            }

            if ($null -ne $remainingWhiteSpace) {
                Write-Debug 'Removing remaining whitespace from line'
                $line = ( -join ( $line[0..($line.Length - $remainingWhiteSpace.Length)]))
                Write-Debug "line is now [[regex]::Escape($line)]"
            }

            $words = $line.Split($separator)
            Write-Debug "Split line into $($words.Count) words"

            #endregion Initialize line
            #-------------------------------------------------------------------------------

            :word foreach ($word in $words) {
                #-------------------------------------------------------------------------------
                #region ! foreach Word

                Write-Debug "-- {{{ -Word '$([regex]::Escape($word))' --"
                Write-Position
                #-------------------------------------------------------------------------------
                #region Initialize word
                $wordIndex++
                $totalWordCount++

                $wordStartIndex = $cursor
                $wordEndIndex = ($cursor + $word.Length)

                $isFirstWord = ($wordIndex -eq 0)
                $isLastWord = ($wordIndex -eq ($words.Count - 1))

                #endregion Initialize word
                #-------------------------------------------------------------------------------

                if ($isLastWord) {
                    Write-Debug '- Last word in line'
                    #TODO: The next word should be the first word of the next line here?
                    $nextWord = "`n"
                    $isLastWord = $false
                } else {
                    $nextWord = $words[($wordIndex + 1)]
                    $isLastWord = $true
                }


                (@(
                    '-- {{{ info block --'
                    "| This is word ($totalWordCount) scanned in the input so far",
                    "|- Index:     $($options.Index)",
                    "|- Line:      $lineNumber",
                    "|- Cursor:    $cursor",
                    "|- Column:    $column",
                    '|- ---',
                    "|- Start:    Line: $($options.Start.Line):$($options.Start.Column) - Index $($options.Start.Index)]",
                    "|- End:      Line: $($options.End.Line):$($options.End.Column) - Index $($options.End.Index)]",
                    '|- ---',
                    "|- This is word $($wordIndex + 1) of $($words.Count) in this line"
                    "|- Is first word:  $isFirstWord",
                    "|- Is last word:  $isLasttWord",
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

                #TODO: Record any space after CLOSE for RemainingWhiteSpace
                :scan switch -Regex -CaseSensitive ($word) {
                    '(^$|\t)' {
                        #-------------------------------------------------------------------------------
                        #region ! word is null
                        Write-Debug '-- {{{ SCAN: whitespace --'
                        <#
                        The only significant whitespace is in the indent or the remainingWhitespace, so just add it
                        in here
                        #>
                        [void]$options.Content.Append($separator)
                        Write-Debug '-- }}} --'
                        #endregion word is null
                        #-------------------------------------------------------------------------------
                    }
                    $startTagPattern {
                        <#
                        this is the start of an element
                        The cursor should be on the last character before the starttag
                        -- Resolve Prefix
                        Get the prefix if there is one
                        Test if this is an escaped start tag
                        - if it is:
                        Add the "un-escaped" start tag to content and continue on to the next word
                        - if it is not
                        Add the contents of the right-side of the tag to $options.Prefix
                        --
                        If the state is not 'OPEN' or 'ELMT', then
                        -- Test "existing content"
                        - if there is content
                        Set the Ending position should be the character before the start tag
                        Create the Token
                        Reset the option fields
                        The Starting position should be the first character of the start tag
                        Set the state to OPEN
                        Advance the cursor and column to the last character of the start tag + Prefix
                        - if there is no content
                        The Starting position should be the first character of the start tag
                        Set the state to OPEN
                        Advance the cursor and column to the last character of the start tag + Prefix

                        Issue 1: because we reset the content after the start tag was found, the next word
                        thinks it does not need to add a space (so it should do that if state is OPEN)
                        #>
                        #-------------------------------------------------------------------------------
                        #region ! word matches start tag
                        Write-Debug '-- {{{ SCAN: Start tag --'

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
                                Write-Debug '** Error Found start tag in element **'
                            }

                            default {
                                Write-Debug '-- {{{ START TAG :: default --'
                                <#
                                    If there is already content recorded, then that token needs to be created.
                                    - The End position should be the character just before the first character of
                                      the start tag.
                                #>
                                if ($options.Content.Length -gt 0) {
                                    Write-Debug 'There is content from the previous block.  Create token'

                                    $options.Type = 'text'
                                    Write-Debug '- Set End position for the previous content before advancing'
                                    Write-Position
                                    Set-EndPosition
                                    New-TemplateToken @options

                                    Update-Cursor
                                    Update-Column
                                    Reset-TokenOption -IncludeContent
                                    Write-Position
                                    Set-StartPosition

                                } else {
                                    Write-Debug 'Content is empty'
                                    # If the first word in the input is a start tag, there
                                    # wont be any input.  Set the Start position here and then update the position
                                    Set-StartPosition
                                    if ($isFirstWord) {
                                        $lexeme = $word
                                    } else {
                                        $lexeme = ( -join ($separator, $word))
                                    }
                                    Write-Position
                                    Update-Cursor
                                    Update-Column
                                }

                                Write-Debug "STATE CHANGE: $state -> OPEN"
                                $state = [TokenState]::OPEN
                                if ($hasPrefix) {
                                    #TODO: Here we would process prefix and next word to determine the type
                                    $options.Prefix = $rightOfStartTag
                                }
                                #! do not process any more scan conditions
                                continue scan

                                Write-Debug '-- }}} --'
                            }
                        } # end startState

                        Write-Debug '-- }}} --'
                        #endregion word matches start tag
                        #-------------------------------------------------------------------------------
                    } # end start tag
                    $endTagPattern {
                        #-------------------------------------------------------------------------------
                        #region ! word matches end tag
                        Write-Debug '-- {{{ SCAN: End Tag --'

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
                                Write-Debug '- Characters found is a Suffix'
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
                                Write-Debug '-- {{{ END TAG :: default --'
                                #TODO: Process the Prefix, Suffix and keywords

                                #-------------------------------------------------------------------------------
                                #region ! Create Expression

                                $options.Type = 'elmt'

                                if ($hasSuffix) {
                                    $options.Suffix = $leftOfEndTag
                                }
                                $options.Indent = $indent
                                $options.RemainingWhiteSpace = $remainingWhiteSpace
                                if ($isFirstWord) {
                                    $lexeme = $word
                                } else {
                                    $lexeme = ( -join ($separator, $word))
                                }
                                Write-Debug "lexeme is [$lexeme]"
                                Write-Debug "- Advance the cursor and column by $($lexeme.Length) to the end of the end tag"
                                Update-Cursor
                                Update-Column
                                Write-Position
                                Set-EndPosition

                                Write-Debug '**** Create Token ****'
                                New-TemplateToken @options

                                #endregion Create Expression
                                #-------------------------------------------------------------------------------

                                #-------------------------------------------------------------------------------
                                #region ! Update
                                Reset-TokenOption -IncludeContent
                                Update-Cursor 1
                                Update-Column 1
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
                        #-------------------------------------------------------------------------------
                        #region ! word did not match
                        Write-Debug '-- {{{ SCAN: default ---------------------------------------------------------'
                        Write-Debug "Check condition when state is $state"
                        switch ($state) {
                            ([TokenState]::OPEN) {
                                #TODO: This is the first word after an open tag. Check for keyword
                                Write-Debug '- state condition: OPEN'
                                Write-Debug "STATE CHANGE: $state -> ELMT"
                                $state = [TokenState]::ELMT
                            }
                            ([TokenState]::CLOSE) {
                                Write-Debug '- state condition: CLOSE'
                                Write-Debug "STATE CHANGE: $state -> TEXT"
                                $state = [TokenState]::TEXT
                                Set-StartPosition
                            }
                            default {
                                Write-Debug '- state condition: default'
                            }
                        }
                        Write-Debug '- Adding to content'
                        if ($isFirstWord) {
                            $lexeme = $word
                        } else {
                            $lexeme = ( -join ($separator, $word))
                        }
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

                (@(
                    "Finished scanning word [$word]",
                    '-- }}} --'
                    ''

                ) -join "`n") | Write-Debug
                #endregion foreach Word
                #-------------------------------------------------------------------------------
            }
            Write-Debug '- Add a newline to content'

            # Start here tomorrow.  The new line being appended is all wrong
            #TODO: I need to move this line ending into the Element
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
            Write-Debug 'END OF LINE'
            Write-Debug '-- }}} --'
            if ($lineNumber -le $lines.Count) {
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
