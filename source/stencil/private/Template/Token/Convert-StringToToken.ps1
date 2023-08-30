
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
        #region regex patterns

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
        Write-Debug "Template is $($Template.Length) characters"
        #-------------------------------------------------------------------------------
        #region Split input

        # Split input into lines
        $lines = $Template.Split("`n")
        Write-Debug "Template contains $($lines.Count) lines"

        # each line is split into "words"
        $separator = ([char]' ')

        #endregion Split input
        #-------------------------------------------------------------------------------

        #-------------------------------------------------------------------------------
        #region initialize tokenizer

        # keep track of our position in the input
        $cursor = 0

        # TODO: Add the level to the options
        # keep track of open and close tags
        $level = 0

        # keep track of "words" across the entire Template
        $totalWordCount = 0

        # The current state of the cursor
        [TokenState]$state = [TokenState]::TEXT

        # Options for creating a new Token
        $options = @{
            Type                = 'Text'
            # The counter Index of the token (first token => 0)
            Order               = 0
            # The options.LineNumber in the file
            LineNumber          = 0
            # the spaces or tabs prior to the start tag
            Indent              = ''
            # The content is the "body" of the token
            Content             = [System.Text.StringBuilder]::new()
            # Zero-based position that the token starts at
            Start               = 0
            # The prefix just after the start marker
            Prefix              = ''
            # The prefix just before the end marker
            Suffix              = ''
            # Any whitespace after the token
            RemainingWhiteSpace = ''
        }

        #endregion initialize tokenizer
        #-------------------------------------------------------------------------------
    }
    process {
        Write-Verbose '- Tokenizing template'


        :line foreach ($line in $lines) {
            #-------------------------------------------------------------------------------
            #region foreach Line
            Write-Debug ("$('=' * 35) Line {0:d3} $('=' * 36)" -f $options.LineNumber)
            Write-Debug $line
            #-------------------------------------------------------------------------------
            #region Initialize line

            # counter for words in the current line
            $wordCount = 0
            $column = 0
            $words = $line.Split($separator)

            #endregion Initialize line
            #-------------------------------------------------------------------------------
            :word foreach ($word in $words) {
                #-------------------------------------------------------------------------------
                #region foreach Word
                if ($wordCount -lt $words.Length) {
                    $nextWord = $words[($wordCount + 1)]
                }
                #TODO: Add the space to the front of the word only if it is not the first word in the token
                if ($options.Content.Length -eq 0) {
                    $lexeme = "$word"
                } else {
                    $lexeme = ( -join ($separator, $word))
                }
                $debugHeader = (@(
                        "$('-' * 40)",
                        "Index - ($totalWordCount):",
                        "- Order:     $($options.Order)",
                        "- Line:      $($options.LineNumber)",
                        "- Cursor:    $cursor",
                        "- Column:    $column",
                        '- ---',
                        "- WordCount: $wordCount"
                        "- Previous:  [$prevWord]",
                        "- Word:      [$word] <---",
                        "- Next:      [$nextWord]",
                        '- ---',
                        "- State:     $state",
                        "- Content:   [$($options.Content.ToString())]",
                        "- Prefix:    [$($options.Prefix)]",
                        "- Suffix:    [$($options.Suffix)]"

                    ) -join "`n")
                Write-Debug $debugHeader

                :scan switch -Regex -CaseSensitive ($word) {

                    '^$' {
                        #-------------------------------------------------------------------------------
                        #region word is null
                        #TODO: What about tabs?
                        #TODO: Record any space after CLOSE for RemainingWhiteSpace
                        Write-Debug 'MATCH: Null - add a space to content'
                        [void]$options.Content.Append($separator)
                        if ($column -eq 0) {
                            Write-Debug '- space after newline (add to indent)'
                            $options.Indent = 1
                        } elseif ($options.Indent -gt 0) {
                            $options.Indent++
                            Write-Debug "- Adding to indent. Now $($options.Indent)"
                        }

                        #endregion word is null
                        #-------------------------------------------------------------------------------
                    }
                    $startTagPattern {
                        #-------------------------------------------------------------------------------
                        #region word matches start tag

                        Write-Debug "MATCH: Start tag ($startTagPattern)"
                        #-------------------------------------------------------------------------------
                        #region Process prefix
                        $hasPrefix = $false
                        if ($null -ne $Matches.rightOf) {
                            $rightOfStartTag = $Matches.rightOf

                            if ($rightOfStartTag.Substring(0, 1) -eq $escapeChar) {
                                #-------------------------------------------------------------------------------
                                #region Escaped Start

                                Write-Debug 'ESCAPED START - Add start tag to content'
                                # The first character is an escape character
                                # add the start tag and the other characters from the prefix
                                # so '<%%want_to_keep' becomes '<%want_to_keep'
                                #! Advance the cursor because we are going onto the next word
                                $lexeme = ( -join (
                                        $separator,
                                        ($word -replace [regex]::Escape("$escapeChar$endTag"), $endTag)
                                    ))

                                $state = [TokenState]::OPEN
                                [void]$options.Content.Append( $lexeme )
                                $cursor = $cursor + $lexeme.Length
                                #! Move onto the next word
                                continue word

                                #endregion Escaped Start
                                #-------------------------------------------------------------------------------
                            } else {
                                # The match is the prefix. Signal for inclusion
                                $level++
                                $hasPrefix = $true
                            }
                        }
                        #endregion Process prefix
                        #-------------------------------------------------------------------------------

                        :startState switch ($state) {

                            ([TokenState]::OPEN) {
                                Write-Debug '** Error Found start tag after start tag **'
                            }

                            ([TokenState]::ELMT) {
                                Write-Debug '** Error Found start tag in element'
                            }

                            default {

                                #-------------------------------------------------------------------------------
                                #region Create text token
                                if ($options.Content.Length -gt 0) {
                                    $options.Type = 'text'

                                    Write-Debug '** Create Token **'
                                    New-TemplateToken @options
                                }
                                #endregion Create text token
                                #-------------------------------------------------------------------------------
                                #-------------------------------------------------------------------------------
                                #region Reset
                                [ref]$options | Reset-TokenOption -IncludeContent
                                $options.Start = $cursor
                                #endregion Reset
                                #-------------------------------------------------------------------------------
                                Write-Debug 'STATE CHANGE: OPEN'
                                $state = [TokenState]::OPEN
                                #TODO: Here we would process prefix and next word to determine the type
                                if ($hasPrefix) {
                                    $options.Prefix = $rightOfStartTag
                                }
                                continue scan
                            }

                        } # end startState

                        #endregion word matches start tag
                        #-------------------------------------------------------------------------------
                    } # end start tag
                    $endTagPattern {
                        #-------------------------------------------------------------------------------
                        #region word matches end tag

                        Write-Debug 'MATCH: End Tag'
                        #-------------------------------------------------------------------------------
                        #region Process suffix

                        $hasSuffix = $false
                        if ($null -ne $Matches.leftOf) {
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
                                [void]$options.Content.Append( $lexeme )
                                #TODO: Consider Update-Position internal function for this
                                #$cursor = $cursor + $lexeme.Length
                                #$column = $column + $lexeme.Length
                                #! Move onto the next word
                                #continue word
                            } else {
                                # The match is the prefix. Signal for inclusion
                                $hasSuffix = $true
                            }
                        }
                        #endregion Process suffix
                        #-------------------------------------------------------------------------------
                        :endState switch ($state) {
                            ([TokenState]::ELMT) {
                                #TODO: Process the Prefix, Suffix and keywords
                                #-------------------------------------------------------------------------------
                                #region Create Expression

                                $options.Type = 'elmt'
                                if ($hasSuffix) {
                                    $options.Suffix = $leftOfEndTag
                                }
                                Write-Debug '** Create Token **'

                                New-TemplateToken @options

                                #endregion Create Expression
                                #-------------------------------------------------------------------------------
                                #-------------------------------------------------------------------------------
                                #region Reset
                                [ref]$options | Reset-TokenOption -IncludeContent
                                #TODO: Ensure we set the cursor to the proper location
                                $options.Start = $cursor

                                Write-Debug 'STATE CHANGE: CLOSE'
                                $state = [TokenState]::CLOSE

                                #continue scan
                                #endregion Reset
                                #-------------------------------------------------------------------------------
                            }
                            ([TokenState]::OPEN) {
                                #! element has no content
                            }

                        } # end endState

                        #endregion word matches end tag
                        #-------------------------------------------------------------------------------
                    }
                    default {
                        #-------------------------------------------------------------------------------
                        #region word did not match

                        switch ($state) {
                            ([TokenState]::OPEN) {
                                #TODO: This is the first word after an open tag. Check for keyword
                                Write-Debug 'STATE CHANGE: ELMT'
                                $state = [TokenState]::ELMT
                            }
                            ([TokenState]::CLOSE) {
                                Write-Debug 'STATE CHANGE: TEXT'
                                $state = [TokenState]::TEXT
                            }
                        }
                        Write-Debug 'MATCH: default'
                        Write-Debug 'Adding to content'
                        [void]$options.Content.Append($lexeme)

                        #-------------------------------------------------------------------------------
                        #region Reset
                        $options.Indent = 0
                        #endregion Reset
                        #-------------------------------------------------------------------------------

                        #endregion word did not match
                        #-------------------------------------------------------------------------------
                    }
                } # end scan

                $prevWord = $word
                #-------------------------------------------------------------------------------
                #region Increment counters

                $cursor = $cursor + $lexeme.Length
                $column = $column + $lexeme.Length
                $wordCount++
                $totalWordCount++

                #endregion Increment counters
                #-------------------------------------------------------------------------------
                #endregion foreach Word
                #-------------------------------------------------------------------------------
            }
            [void]$options.Content.AppendLine()
            Write-Debug "== End Line ('=' * 69)"
            $options.LineNumber++
            #endregion foreach Line
            #-------------------------------------------------------------------------------
        }

        #-------------------------------------------------------------------------------
        #region remaining content

        Write-Debug 'Reached End of input'
        if ($options.Content.Length -gt 0) {
            Write-Debug 'Processing remaining content'
            switch ($state) {
                    ([TokenState]::OPEN) {
                    $message = 'Error in template. No closing tag found before end of input'
                    $exceptionText = $message
                    $thisException = [Exception]::new($exceptionText)
                    $eRecord = New-Object System.Management.Automation.ErrorRecord -ArgumentList (
                        $thisException,
                        $null, # errorId
                        0, # errorCategory
                        $null  # targetObject
                    )
                    $PSCmdlet.ThrowTerminatingError( $eRecord )


                }
                    ([TokenState]::TEXT) {
                    $options.Type = 'text'

                    Write-Debug '** Create Token **'
                    New-TemplateToken @options
                    [ref]$options | Reset-TokenOption -IncludeContent
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
