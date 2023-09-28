
function Convert-StringToToken {
    <#
    .SYNOPSIS
        Convert a String into a list of Tokens
    .DESCRIPTION
    .NOTES

    Start and End Positions:
    - Index: A zero-based position in the input suitable for "slicing the content" (such as `$content[9]`)
    - Line: A one-based line number (same as the line number shown in editors, grep results, etc)
    - Column: A one-based position on the line (same as the column number shown in editors, grep results, etc)

    Line Endings:
    - A Carriage Return-LineFeed (\r\n) at the end of the line would be two advances of the Index, but only one of
      the column
    .EXAMPLE
        Convert-StringToToken $template
    .LINK
        New-TemplateToken
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

        function Write-Position {
            <#
            .SYNOPSIS
                Pretty-print the line with position information
            #>
            @'
+-- {0} - Column {1:d2} ----------------------------------------------------------------+
|- 0    5   10    15   20   25   30   35   40   45   50   55   60   65   70   75   80
|- |....|....|....|....|....|....|....|....|....|....|....|....|....|....|....|....|
|   {2}
|  {3}^
+------------------------------------------------------------------------------- {4} --+
'@ -f '{{{', $column, $line, ('-' * $column), '}}}' | Write-Debug

        }

        #-------------------------------------------------------------------------------
        #region ! initialize tokenizer

        $config = Import-Configuration | Select-Object -ExpandProperty Template

        $newline = [char]"`n"
        $return  = [char]"`r"
        $tab     = [char]"`t"
        $space   = [char]' '

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


        #TODO: Consider having an initital state like 'NONE' to deal with first word positioning
        enum TokenState  {
            TEXT # Inside a Text block
            OPEN # Start tag found
            ELMT # Within an element
            CLOSE # End tag found
        }

        enum LineEndingType {
            LF # \n only
            CRLF # \r\n
        }
        Write-Debug "Template is $($Template.Length) characters"


        # keep track of our position in the input
        $cursor     = 0
        $column     = 0
        $lineNumber = 0


        # TODO: Add the level to the options
        # keep track of open and close tags
        $level = 0

        # keep track of "words" across the entire Template
        $totalWordCount = -1

        # Assume the line ending type is Unix
        $lineEnding = [LineEndingType]::LF

        # The current state of the cursor
        [TokenState]$state = [TokenState]::TEXT


        #TODO: Consider creating a table of all the pointers that could be passed to other functions to maintain position information
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
                Line   = 1
                Column = 1
            }
            # Position information for end of the token
            End                 = @{
                Index  = 0
                Line   = 1
                Column = 1
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
        Write-Debug 'Beginning tokenization'
        #-------------------------------------------------------------------------------
        #region ! Split input into lines
        $lines = [System.Collections.ArrayList]::new($Template.Split($newline))
        Write-Debug "Template contains $($lines.Count) lines"

        $lastLine = $lines[($lines.Count - 1)]
        Write-Debug "- Last line is '$([regex]::Escape($lastLine))'"
        if ($lastLine -match '^$') {
            Write-Debug '- Removing extra line at file end (will be added if config.AddFinalNewLine is set)'
            [void]$lines.RemoveAt( ($lines.Count - 1) )
            Write-Debug "- Now Template contains $($lines.Count) lines"
            $insertFinalNewLine = $true
        } else {
            $insertFinalNewLine = $false
        }

        #endregion Split input into lines
        #-------------------------------------------------------------------------------

        Write-Debug 'Processing lines in input'
        :line foreach ($line in $lines) {
            #-------------------------------------------------------------------------------
            #region ! foreach Line

            $lineNumber++
            Write-Debug "-- {{{ - Line $lineNumber --"
            #-------------------------------------------------------------------------------
            #region ! Line position

            $isFirstLine = ($lineNumber -eq 1)
            $isLastLine = ($lineNumber -eq ($lines.Count))

            if ($lines.Count -gt 1) {
                if ($isLastLine) {
                    Write-Debug '- Last line in content'
                }

                if ($isFirstLine) {
                    Write-Debug '- First line in content'
                }
            } else {
                Write-Debug '- Content only contains 1 line'
            }

            #endregion Line position
            #-------------------------------------------------------------------------------
            #-------------------------------------------------------------------------------
            #region ! Handle line endings

            $carriageReturn = $line.IndexOf($return)
            if ( $carriageReturn -gt 0) {
                #TODO: Do we care if it at the end or not?
                $lineEnding = [LineEndingType]::CRLF
                Write-Debug "Remove Carriage Return (\r) mark at index $carriageReturn"
                $line = $line -replace [regex]::Escape($return), ''
            } else {
                Write-Debug 'No Carriage Return found'
                $lineEnding = [LineEndingType]::LF
            }

            #endregion Handle line endings
            #-------------------------------------------------------------------------------
            Write-Debug "Current line: '$([regex]::Escape($line))'"
            #-------------------------------------------------------------------------------
            #region ! Handle whitespace

            if ($line -match $indentPattern) {
                Write-Debug '- Found indentation on this line'
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
                Write-Debug '- Found whitespace at end of this line'
                switch ($state) {
                    default {
                        Write-Debug '-- {{{ Remaining :: default --'
                        $remainingWhiteSpace = $Matches.remain
                        Write-Debug '-- }}} --'
                    }
                }
            } else {
                $remainingWSPattern = $null
            }

            #endregion Handle whitespace
            #-------------------------------------------------------------------------------

            #-------------------------------------------------------------------------------
            #region ! Initialize current line

            # reset Column to start of line
            $column = 1

            # counter for words in the current line
            $wordIndex = 0

            # track the last word of the line
            $isLastWord = $false

            # track the first word of the line
            $isFirstWord = $false


            if ($null -ne $indent) {
                Write-Debug 'Removing indent from line:'
                Write-Debug "- line is '$([regex]::Escape($line))'"
                Write-Debug "- indent is '$([regex]::Escape($indent))'"
                Write-Debug "- Line length: $($line.Length)"
                Write-Debug "- indent length: $($indent.Length)"
                $line = $line.Substring($indent.Length)
                Write-Debug "line is now '$([regex]::Escape($line))'"
                [ref]$column | Move-Position $indent.Length
                [ref]$cursor | Move-Position $indent.Length
            }

            if ($null -ne $remainingWhiteSpace) {
                Write-Debug 'Removing remaining whitespace from line'
                $line = $line.SubString(0, ($line.Length - $remainingWhiteSpace.Length))
                Write-Debug "line is now '$([regex]::Escape($line))'"
            }

            $words = $line.Split($space)
            Write-Debug "Split line into $($words.Count) words"

            #endregion Initialize current line
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

                $isFirstWord = ($wordIndex -eq 1)
                $isLastWord = ($wordIndex -eq $words.Count)


                if ($isLastWord) {
                    Write-Debug '- Last word in line'
                    #TODO: The next word should be the first word of the next line here?
                    $nextWord = $null
                } else {
                    $nextWord = $words[($wordIndex + 1)]
                }


                (@(
                    '-- {{{ info block --'
                    "| This is word ($totalWordCount) scanned in the input so far",
                    "|- Index:     $($options.Index)",
                    "|- Line:      $lineNumber",
                    "|- Cursor:    $cursor",
                    "|- Column:    $column",
                    '|- ---',
                    "|- Start:    Line: $($options.Start.Line):$($options.Start.Column) - Index $($options.Start.Index)",
                    "|- End:      Line: $($options.End.Line):$($options.End.Column) - Index $($options.End.Index)",
                    '|- ---',
                    "|- This is word $wordIndex of $($words.Count) in this line"
                    "|- Is first word:  $isFirstWord",
                    "|- Is last word:  $isLastWord",
                    "|- Previous word:  [$prevWord]",
                    "|- Current word:   [$word] <---",
                    "|- Next word:      [$nextWord]",
                    '|- ---',
                    "|- State:     $state",
                    "|- Content:   [$($options.Content.ToString())]",
                    "|- Prefix:    [$($options.Prefix)]",
                    "|- Suffix:    [$($options.Suffix)]",
                    '-- }}} --'
                ) -join "`n") | Write-Debug

                #endregion Initialize word
                #-------------------------------------------------------------------------------

                #-------------------------------------------------------------------------------
                #region ! Scan current word
                Write-Debug "Scanning current word '$word' for matches"
                :scan switch -Regex -CaseSensitive ($word) {
                    '^$' {
                        #-------------------------------------------------------------------------------
                        #region ! word is null
                        Write-Debug '-- {{{ SCAN MATCH: space character --'
                        <#
                        The only significant whitespace is in the indent or the remainingWhitespace, so just add the
                        space to content and advance
                        #>
                        [void]$options.Content.Append($space)
                        [ref]$cursor | Move-Position 1
                        [ref]$column | Move-Position 1
                        Write-Debug '-- }}} --'
                        #endregion word is null
                        #-------------------------------------------------------------------------------
                    }
                    '\t' {
                        #-------------------------------------------------------------------------------
                        #region ! word is tab
                        Write-Debug '-- {{{ SCAN MATCH: tab character --'
                        <#
                        The only significant whitespace is in the indent or the remainingWhitespace, so just add the
                        tab to content and advance
                        #>
                        [void]$options.Content.Append($tab)
                        [ref]$cursor | Move-Position 1
                        [ref]$column | Move-Position 1
                        Write-Debug '-- }}} --'
                        #endregion word is tab
                        #-------------------------------------------------------------------------------
                    }
                    $startTagPattern {
                        #-------------------------------------------------------------------------------
                        #region ! word matches start tag
                        Write-Debug '-- {{{ SCAN MATCH: Start tag --'

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
                                        $space,
                                        ($word -replace [regex]::Escape("$startTag$EscapeChar"), $startTag)
                                    ))
                                Write-Debug "  - Adding $lexeme to content"
                                [void]$options.Content.Append( $lexeme )
                                #TODO: What other counters need to be incremented if the start tag is escaped?
                                [ref]$cursor | Move-Position $lexeme.Length
                                [ref]$column | Move-Position $lexeme.Length
                                #! Move onto the next word
                                Write-Debug '-- }}} --'
                                continue scan

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
                                    [ref]$options | Set-EndPosition -Index $cursor -Line $lineNumber -Column $column
                                    New-TemplateToken @options

                                    [ref]$cursor | Move-Position $lexeme.Length
                                    [ref]$column | Move-Position $lexeme.Length
                                    Reset-TokenOption -IncludeContent
                                    Write-Position
                                    [ref]$options | Set-StartPosition -Index $cursor -Line $lineNumber -Column $column

                                } else {
                                    Write-Debug 'Content is empty'
                                    # If the first word in the input is a start tag, there
                                    # wont be any input.  Set the Start position here and then update the position
                                    #TODO: Should I reset the EndPosition at the same time as setting the StartPosition?
                                    [ref]$options | Set-StartPosition -Index $cursor -Line $lineNumber -Column $column
                                    if ($isFirstWord) {
                                        $lexeme = $word
                                        #! if this tag is the first word in the line then the cursor is already
                                        #! at the start of the tag which is one off
                                        #TODO: It may only be the first line so use $isFirstLine
                                        [ref]$cursor | Move-Position ($lexeme.Length - 1)
                                        [ref]$column | Move-Position ($lexeme.Length - 1)
                                    } else {
                                        $lexeme = ( -join ($space, $word))
                                        [ref]$cursor | Move-Position $lexeme.Length
                                        [ref]$column | Move-Position $lexeme.Length
                                    }
                                    Write-Position
                                }

                                Write-Debug "STATE CHANGE: $state -> OPEN"
                                $state = [TokenState]::OPEN
                                if ($hasPrefix) {
                                    #TODO: Here we would process prefix and next word to determine the type
                                    $options.Prefix = $rightOfStartTag
                                }
                                #! do not process any more scan conditions
                                Write-Debug '-- }}} --'
                                Write-Debug '-- }}} --'
                                continue scan

                            }
                        } # end startState

                        Write-Debug '-- }}} --'
                        #endregion word matches start tag
                        #-------------------------------------------------------------------------------
                    } # end start tag
                    $endTagPattern {
                        #-------------------------------------------------------------------------------
                        #region ! word matches end tag
                        Write-Debug '-- {{{ SCAN MATCH: End Tag --'

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
                                        $space,
                                        ($word -replace [regex]::Escape("$escapeChar$endTag"), $endTag)
                                    ))
                                Write-Debug "- Adding $lexeme to content"
                                [void]$options.Content.Append( $lexeme )
                                [ref]$cursor | Move-Position $lexeme.Length
                                [ref]$column | Move-Position $lexeme.Length
                                Write-Debug '-- }}} --'
                                Write-Debug '-- }}} --'
                                continue word
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

                                if ($hasSuffix) {
                                    $options.Suffix = $leftOfEndTag
                                }

                                if ($isFirstWord) {
                                    $lexeme = $word
                                    #! if this tag is the first word in the line then the cursor is already
                                    #! at the start of the tag which is one off
                                    #TODO: It may only be the first line so use $isFirstLine
                                    [ref]$cursor | Move-Position ($lexeme.Length - 1)
                                    [ref]$column | Move-Position ($lexeme.Length - 1)
                                } else {
                                    $lexeme = (-join ($space, $word))
                                }
                                Write-Debug "- lexeme is [$lexeme]"
                                [ref]$cursor | Move-Position $lexeme.Length
                                [ref]$column | Move-Position $lexeme.Length


                                if ($isLastWord) {
                                    <#
                                    If this is the last word on the line, then we add the appropriate characters to
                                    the remainingWhitespace
                                    #>
                                    Write-Debug "- Last word in line $lineNumber"
                                    switch ($lineEnding) {
                                        ([LineEndingType]::CRLF) {
                                            Write-Debug '- Add CRLF'
                                            $options.RemainingWhiteSpace = "$($options.RemainingWhiteSpace)$return$newline"
                                            #! Adding CRLF is only one column but two cursors
                                            [ref]$column | Move-Position ($options.RemainingWhiteSpace.Length - 1)
                                            [ref]$cursor | Move-Position ($options.RemainingWhiteSpace.Length)
                                        }
                                        ([LineEndingType]::LF) {
                                            Write-Debug '- Add LF'
                                            $options.RemainingWhiteSpace = "$($options.RemainingWhiteSpace)$newline"
                                            [ref]$column | Move-Position ($options.RemainingWhiteSpace.Length)
                                            [ref]$cursor | Move-Position ($options.RemainingWhiteSpace.Length)
                                        }
                                    }
                                }
                                # There was a space prior to the end tag, add that back to the content
                                [void]$options.Content.Append($space)
                                Write-Debug "  - And remaining whitespace $($options.RemainingWhiteSpace.Length)"
                                Write-Position
                                [ref]$options | Set-EndPosition -Index $cursor -Line $lineNumber -Column $column

                                Write-Debug '**** Create Token ****'
                                $options.Type = 'elmt'
                                $options.Indent = $indent
                                $options.RemainingWhiteSpace = $remainingWhiteSpace

                                New-TemplateToken @options

                                #endregion Create Expression
                                #-------------------------------------------------------------------------------

                                #-------------------------------------------------------------------------------
                                #region ! Update
                                Reset-TokenOption -IncludeContent

                                [ref]$options | Set-StartPosition -Index ($cursor + 1) -Line $lineNumber -Column ($column + 1)


                                Write-Debug "STATE CHANGE: $state -> CLOSE"
                                $state = [TokenState]::CLOSE


                                Write-Debug '--}}} --'
                                #endregion Update
                                #-------------------------------------------------------------------------------
                            } # end endState

                            #endregion word matches end tag
                            #-------------------------------------------------------------------------------
                        }
                    }
                    default {
                        #-------------------------------------------------------------------------------
                        #region ! word match default
                        Write-Debug '-- {{{ SCAN MATCH: ''default'' --'
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
                            }
                            default {
                                Write-Debug '- state condition: default'
                            }
                        }

                        if ($isFirstWord) {
                            $lexeme = $word
                            [ref]$cursor | Move-Position ($lexeme.Length - 1)
                            [ref]$column | Move-Position ($lexeme.Length - 1)
                        } else {
                            $lexeme = ( -join ($space, $word))
                            [ref]$cursor | Move-Position $lexeme.Length
                            [ref]$column | Move-Position $lexeme.Length
                        }

                        Write-Debug '- Adding to content'
                        [void]$options.Content.Append($lexeme)

                        if ($isLastWord) {
                            Write-Debug "- Last word in line $lineNumber"
                            switch ($lineEnding) {
                                ([LineEndingType]::CRLF) {
                                    Write-Debug '- Add CRLF'
                                    [void]$options.Content.Append("$return$newline")
                                    #! Adding CRLF is only one column but two cursors
                                    [ref]$column | Move-Position 1
                                    [ref]$cursor | Move-Position 2
                                }
                                ([LineEndingType]::LF) {
                                    Write-Debug '- Add LF'
                                    [void]$options.Content.Append($newline)

                                    [ref]$column | Move-Position 1
                                    [ref]$cursor | Move-Position 1
                                }
                            }
                        }
                        Write-Debug '-- }}} --'
                        #endregion word match default
                        #-------------------------------------------------------------------------------
                    }
                } # end scan

                #endregion ! Scan current word
                #-------------------------------------------------------------------------------
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
            Write-Debug 'END OF LINE'
            Write-Debug '-- }}} --'
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
                    if ($config.AddFinalNewLine) {
                        if ($insertFinalNewLine) {
                            [void]$options.Content.Append($newline)
                            [ref]$column | Move-Position 1
                            [ref]$cursor | Move-Position 1
                            $lineNumber++
                        }
                    }
                    [ref]$options | Set-EndPosition -Index $cursor -Line $lineNumber -Column $column
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
