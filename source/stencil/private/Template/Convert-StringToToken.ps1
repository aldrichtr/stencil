
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
        [string]$Template,

        # The data to supply to the template
        [Parameter(
        )]
        [hashtable]$Data

    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"

        $config = Import-Configuration | Select-Object -ExpandProperty Template

        if ($null -ne $config) {
            if (($config.ContainsKey('TagStyleMap')) -and
                (-not ([string]::IsNullOrEmpty($config.TagStyle)))) {
                if ($config.TagStyleMap.ContainsKey($config.TagStyle)) {
                    $startTag, $endTag, $escapeChar = $config.TagStyleMap[$config.TagStyle]
                }
            }
        }

        if (($null -eq $startTag) -or ($null -eq $endTag) -or ($null -eq $escapeChar)) {
            $startTag = '<%'
            $endTag = '%>'
            $escapeChar = '%'
        }

        # literal escape tags
        $lStartTag = "$startTag$escapeChar"
        $lEndTag = "$escapeChar$endTag"
        #TODO: I think that if I remove the "escape" from the regex, I can add the matched content to the previous
        # That way, it will just be one solid block of content, not three
        $templatePattern = [regex]( -join (
                '(?sm)', # look for patterns across the whole string
                "(?<lit>$lStartTag|$lEndTag)", # Start/End tag plus Escape Character
                '|',
                "$startTag(?<prefix>\S)?", # start markers might have additional instructions
                '(?<body>.*?)', # the "body" inside the markers
                '(?<suffix>\S)?', # end markers might have additional instructions '-', '='
                "(?<!$escapeChar)$endTag", # "zero-width lookbehind '(?<!' for a '%' ')'" and match an end marker '%>'
                '(?<rspace>[ \t]*\r?\n)?')    # match the different types of whitespace at the end
        )
        Write-Debug "template pattern is $templatePattern"
        $contentStart = $contentLength = $directiveStart = $directiveLength = 0

        # Options for creating a new Token
        $options = @{
            Type                = 'Text'
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


    }
    process {
        Write-Debug '- Looking for template tokens in content'

        #region Parse the file
        $allMatches = $templatePattern.Matches( $Template )
        #endregion Parse the file

        if ($allMatches.Count -gt 0) {
            Write-Debug "- Found $($allMatches.Count) tokens"
            $count = 0


            foreach ($patternMatch in $allMatches) {
                $count++
                Write-Debug " $('-' * 20)`nThis is match $count`n$($foreach.Current.Value)`n$('-' * 20)"

                # Reset the options for creating the element that will be filled in below
                $options.Type = 'Text'
                $options.Start = 0
                $options.Length = 0
                $options.Prefix = ''
                $options.Suffix = ''
                $options.RemainingWhiteSpace = ''


                #-------------------------------------------------------------------------------
                #region Set Start and Length

                $directiveStart = $patternMatch.Index
                $directiveLength = $patternMatch.Length

                Write-Debug "- Directive Start $directiveStart, length $directiveLength"
                # content is the text in the Template that is between the last match and this one
                $contentLength = $directiveStart - $contentStart
                # The entire contents of the template is stored in $Template
                # here, content is the portion "between directives" in that Template
                $content = $Template.Substring($contentStart, $contentLength)

                Write-Debug "- Content start $contentStart, length $contentLength"
                $options.Start = $contentStart
                $options.Length = $contentLength
                #endregion Set Start and Length
                #-------------------------------------------------------------------------------


                #-------------------------------------------------------------------------------
                #region Literal marker in template

                #! if the user wanted to escape the markers, lit would be matched
                $literal = $patternMatch.Groups['lit']

                if ($literal.Success) {
                    Write-Verbose "Found literal marker in region starting at $($patternMatch.Index)"
                    # Add the literal tag to the content
                    switch ($literal.Value) {
                        $lStartTag {
                            Write-Debug "- Found escaped start marker $lStartTag"
                            $content += $startTag
                            $contentLength = $content.Length
                            Write-Debug "  - Content now start $contentStart, length $contentLength"
                        }
                        $lEndTag {
                            Write-Debug "- Found escaped end marker $lEndTag"
                            $content += $endTag
                            $contentLength = $content.Length
                            Write-Debug "  - Content now start $contentStart, length $contentLength"
                        }
                    }

                    $options.Length = $contentLength

                    Write-Verbose "Creating content element with characters $contentStart to $directiveStart"
                    $options.Content = $content
                    New-TemplateToken @options
                    #endregion Literal marker in template
                    #-------------------------------------------------------------------------------
                } else {
                    #-------------------------------------------------------------------------------
                    #region Create Content Token
                    Write-Debug "Content just before: '$content'"
                    # create a Text token from the content up to the directive
                    $options.Type = 'Text'
                    $options.Start = $contentStart
                    $options.Length = $contentLength
                    $options.Prefix = ''
                    $options.Suffix = ''
                    $options.RemainingWhiteSpace = ''
                    $options.Content = $content
                    New-TemplateToken @options

                    #endregion Create Content Token
                    #-------------------------------------------------------------------------------
                    #-------------------------------------------------------------------------------
                    #region Create Directive Token

                    # Create the Directive token from the captured groups

                    $options.Type = 'Directive'
                    $options.Length = $directiveLength
                    $options.Start = $directiveStart
                    # prefix is the character (if any) after the start tag
                    $options.Prefix = $patternMatch.Groups['prefix'].Value
                    # body is the text "inside" the start and end tag
                    $options.Content = $patternMatch.Groups['body'].Value
                    # suffix is the character (if any) just before the end tag
                    $options.Suffix = $patternMatch.Groups['suffix'].Value
                    # rspace is the additional white space after the directive
                    $options.RemainingWhiteSpace = $patternMatch.Groups['rspace'].Value

                    New-TemplateToken @options

                    #endregion Create Directive Token
                    #-------------------------------------------------------------------------------
                }
                # advance the cursor to the end of the directive
                $contentStart = $directiveStart + $directiveLength
            }
        }

        if ($contentStart -eq 0) {
            Write-Debug 'No matches found. Output the template'
            $options.Type = 'Text'
            $options.Start = 0
            $options.Length = $Template.Length
            $options.Content = $Template
            New-TemplateToken @options
        } elseif ($contentStart -lt $Template.Length) {
            Write-Debug 'No more matches, but still text in the template'
            $options.Type = 'Text'
            $options.Start = $contentStart
            $options.Length = $Template.Length - $contentStart
            $options.Content = $Template.Substring($options.Start, $options.Length)
            New-TemplateToken @options
        }
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
