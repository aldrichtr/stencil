
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

        $lineEndingPattern = '\n'

        # Options for creating a new Token
        $options = @{
            Type                = 'Text'
            # The counter number of the token (first token => 0)
            Number              = 0
            # The lineNumber in the file
            # TODO: How do I get the column number?
            LineNumber          = 0
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
            TEXT
            START_TAG
        }
        Write-Debug "Template is $($Template.Length) characters"
        #-------------------------------------------------------------------------------
        #region Split input

        # Split input into lines
        $lines = $Template.Split("`n")
        Write-Debug "Template contains $($lines.Count) lines"

        # Split input into words
        $separator = ' '
        $buffer = $Template.Split($separator)
        #endregion Split input
        #-------------------------------------------------------------------------------

        #-------------------------------------------------------------------------------
        #region initialize tokenizer

        #keep track of the word in the buffer
        $index = 0
        # keep track of our position in the input
        $cursor = 0
        # record the location that the element started
        $startingCursor = 0

        # keep track of the line number of the cursor
        $lineNumber = 0

        # keep track of the start of this line
        $newLine = 0

        # keep track of open and close tags
        $level = 0

        # store the contents of the current element
        $content = [System.Text.StringBuilder]::new()

        # The current state of the cursor
        [ReadState]$state = [ReadState]::TEXT

        #endregion initialize tokenizer
        #-------------------------------------------------------------------------------
    }
    process {
        Write-Debug '- Looking for template tokens in content'
        #-------------------------------------------------------------------------------
        #region Word

        :word foreach ($word in $buffer) {
            if ($index -lt $buffer.Length) {
                $nextWord = $buffer[($index + 1)]
            }
            #TODO: Add the space to the front of the word only if it is not the first word in the token
            if ($cursor -eq 0) {
                $lexeme = "$word"
            } else {
                $lexeme = ( -join ($separator, $word))
            }
            $debugHeader = (@(
                    "$('-' * 40)",
                    "Index - (${index}):",
                    "- Line:   $lineNumber",
                    "- Cursor: $cursor",
                    "- Word:   [$word]",
                    "- State:  $state",
                    '- ---',
                    "- Content: [$($content.ToString())]",
                    "- Prefix:  [$($options.Prefix)]",
                    "- Suffix:  [$($options.Prefix)]"

                ) -join "`n")
            Write-Debug $debugHeader
            :scan switch -Regex -CaseSensitive ($word) {
                '^$' {
                    #Should be a null which would indicate an additional space
                    Write-Debug 'MATCH: Null - add a space to content'
                    [void]$content.Append($separator)
                    if ($newLine -eq ($cursor - 1)) {
                        Write-Debug '- space after newline (add to indent)'
                        $options.Indent = 1
                    } elseif ($options.Indent -gt 0) {
                        ($options.Indent)++
                        Write-Debug "- Adding to indent. Now $($options.Indent)"
                    }
                }
                $lineEndingPattern {
                    Write-Debug 'MATCH: line ending'
                    Write-Debug "- Word has $($Matches.Count) newlines"
                    $lineNumber = $lineNumber + $Matches.Count

                    $newLine = ($cursor + ($word.LastIndexOf("`n")) + 1)
                    $lineText = $lines[$lineNumber]
                    $options.LineNumber = $lineNumber
                    $options.Indent = 0
                    Write-Debug "- Update lineNumber number to $lineNumber"
                    Write-Debug "- Last line number is at position $newLine"
                    #! omit continue so that other patterns are processed
                }
                $startTagPattern {
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

                            $state = [ReadState]::TEXT
                            $content.Append( $lexeme )
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
                        ([ReadState]::START_TAG) {
                            Write-Debug '** Error Found start tag while in a template element **'
                            Write-Debug "Index ${index}:`n-Content $($content.ToString())`n-Word $word`n-Line ${lineNumber}:`n$lineText"
                            #TODO: Consider a custom exception to throw when nested tag found
                            $message = "Syntax error in Element ${index}: $($content.ToString()) $word`n${lineNumber}:`n$lineText`nNested tags are not supported"
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
                        ([ReadState]::TEXT) {

                            #-------------------------------------------------------------------------------
                            #region Create text token
                            if ($content.Length -gt 0) {
                                $options.Content = $content.ToString()
                                $options.Type = 'text'
                                $options.Start = $startingCursor

                                Write-Debug '** Create Token **'
                                $options
                                | ConvertTo-Psd
                                | Out-String
                                | Write-Debug
                                New-TemplateToken @options
                            }
                            #endregion Create text token
                            #-------------------------------------------------------------------------------
                            #-------------------------------------------------------------------------------
                            #region Reset
                            $options.Indent = 0
                            $options.Number = ($options.Number + 1)
                            $startingCursor = $cursor
                            [void]$content.Clear()

                            #endregion Reset
                            #-------------------------------------------------------------------------------
                            Write-Debug 'STATE CHANGE: START_TAG'
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

                            #! Advance the cursor because we are going onto the next word
                            $lexeme = ( -join (
                                    $separator,
                                        ($word -replace [regex]::Escape("$escapeChar$endTag"), $endTag)
                                ))
                            $content.Append( $lexeme )
                            $cursor = $cursor + $lexeme.Length
                            #! Move onto the next word
                            continue word
                        } else {
                            # The match is the prefix. Signal for inclusion
                            $hasSuffix = $true
                        }
                    }
                    #endregion Process suffix
                    #-------------------------------------------------------------------------------
                    :endState switch ($state) {
                        ([ReadState]::TEXT) {
                            #TODO: Consider a custom exception to throw when nested tag found
                            $message = "Error in template at lineNumber ${lineNumber}:`n$lineText`nEnd tag without start tag"
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
                        ([ReadState]::START_TAG) {


                            #-------------------------------------------------------------------------------
                            #region Create Expression

                            $options.Content = $content.ToString()
                            #TODO: The type will actually depend on  what is in prefix and the first word
                            $options.Type = 'Expression'
                            $options.Start = $startingCursor
                            if ($hasSuffix) {
                                $options.Suffix = $leftOfEndTag
                            }
                            Write-Debug '** Create Token **'
                            $options
                            | ConvertTo-Psd
                            | Out-String
                            | Write-Debug
                            New-TemplateToken @options

                            #endregion Create Expression
                            #-------------------------------------------------------------------------------
                            #-------------------------------------------------------------------------------
                            #region Reset
                            $options.Indent = 0
                            $options.Number = ($options.Number + 1)
                            #TODO: Set the cursor to the proper location
                            $startingCursor = $cursor
                            [void]$content.Clear()

                            #TODO: Is it ok to set the state to TEXT here?
                            Write-Debug 'STATE CHANGE: TEXT'
                            $state = [ReadState]::TEXT
                            continue scan
                            #endregion Reset
                            #-------------------------------------------------------------------------------
                        }
                    } # end endState

                }
                default {
                    Write-Debug 'MATCH: default'
                    Write-Debug 'Adding to content'
                    [void]$content.Append($lexeme)

                    #-------------------------------------------------------------------------------
                    #region Reset
                    $options.Indent = 0
                    #endregion Reset
                    #-------------------------------------------------------------------------------
                }
            } # end scan
            $cursor = $cursor + $lexeme.Length
            $index++
        } # end foreach word

        #endregion Word
        #-------------------------------------------------------------------------------
        # if there is still content
        Write-Debug 'Reached End of input'
        if ($content.Length -gt 0) {
            Write-Debug ''
            switch ($state) {
                ([ReadState]::START_TAG) {
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
                ([ReadState]::TEXT) {
                    $options.Type = 'text'
                    $options.Content = $content.ToString()
                    $options.Start = $startingCursor

                    Write-Debug '** Create Token **'
                    $options
                    | ConvertTo-Psd
                    | Out-String
                    | Write-Debug
                    New-TemplateToken @options

                    $options.Number = ($options.Number + 1)
                    [void]$content.Clear()
                }
            }
        }
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
