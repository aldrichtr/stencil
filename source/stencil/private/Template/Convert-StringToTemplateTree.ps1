function Convert-StringToTemplateTree {
    <#
    .SYNOPSIS
        Convert a String into an "Abstract Syntax Tree"-like structure
    #>
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
        $lStartTag = "$startTag$escapeChar"
        $lEndTag = "$escapeChar$endTag"
        $templatePattern = [regex]( -join (
                '(?sm)', # look for patterns across the whole string
                "(?<lit>$lStartTag|$lEndTag)", # double '%' is used to "escape" template markers '<%%' => '<%' in output
                '|',
                "$startTag(?<instr>={1,2}|-|\+|#)?", # start markers might have additional instructions: currently ('=', '-', '+' or '#')
                '(?<code>.*?)', # the "code" inside the markers
                '(?<tailch>[-=])?', # end markers might have additional instructions '-', '='
                "(?<!$escapeChar)$endTag", # "zero-width lookbehind '(?<!' for a '%' ')'" and match an end marker '%>'
                '(?<rspace>[ \t]*\r?\n)?')    # match the different types of whitespace at the end
        )
        Write-Debug "template pattern is $templatePattern"
        $templateTree = [System.Collections.Generic.List[Object]]::new()
        $contentStart = $contentLength = $directiveStart = $directiveLength = 0
    }
    process {

        Write-Debug '- Looking for template tokens in content'
        $allMatches = $templatePattern.Matches( $Template )
        if ($allMatches.Count -gt 0) {
            Write-Debug "- Found $($allMatches.Count) tokens"
            $count = 0

            <#
             "import" the data into the current session
             TODO: Do we import this here, in the main convert function or when we create the directives?
            #>

            if (-not ([string]::IsNullorEmpty($Data))) {
                Write-Debug '- Importing Data table into current session'
                $Data | Import-DataTable
            }

            <#
            Set the options for creating the element that will be filled in below
            #>

            # TODO: I'm not sure I need to send the length of the content if I'm also sending the content
            $options = @{
                Type                     = 'content'
                Start                    = $contentStart
                Length                   = $contentLength
                RemoveLeadingWhitespace  = $false
                RemoveTrailingLineEnding = $false
            }

            foreach ($patternMatch in $allMatches) {
                $count++
                Write-Debug " $('-' * 20)`nThis is match $count`n$($foreach.Current.Value)`n$('-' * 20)"
                $directiveStart = $patternMatch.Index
                $directiveLength = $patternMatch.Length

                Write-Debug "- Directive Start $directiveStart, length $directiveLength"
                # content is the text in the Template that is between the last match and this one
                $contentLength = $directiveStart - $contentStart
                $content = $Template.Substring($contentStart, $contentLength)

                Write-Debug "- Content start $contentStart, length $contentLength"

                $options.Start = $contentStart
                $options.Length = $contentLength

                if (-not ([string]::IsNullorEmpty($Data))) {
                    $options['Data'] = $Data
                }

                #! if the user wanted to escape the markers, lit would be matched
                $literal = $patternMatch.Groups['lit']
                if ($literal.Success) {
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

                    $null = $templateTree.Add( ($content | New-TemplateElement @options) )
                } else {
                    $instruction = $patternMatch.Groups['instr'].Value
                    $code = $patternMatch.Groups['code'].Value
                    $tail = $patternMatch.Groups['tailch'].Value
                    $rspace = $patternMatch.Groups['rspace'].Value

                    <#
                    TODO: We want to Convert the template string into the proper object and then add it
                    But for now, we can just create a generic object with the right type to
                    prove our methodology is sound
                    $code | ConvertFrom-TemplateString
                    #>


                    if (($instruction -ne '-') -and ($contentLength -ne 0)) {
                        $options.Type = 'content'
                        $null = $templateTree.Add( ($content | New-TemplateElement @options) )

                    }

                    if (($instruction -ne '%') -and
                        (($tail -ne '-') -or ($rspace -match '^[^\r\n]'))) {
                        <#
                        $instruction is the char added to the start marker if any
                        $tail is the char added to the end marker if any

                        if the $instruction isn't a percent (not sure how it could be based on the regex...)
                        and
                        $tail is not a '-' or the end of the match starts with something other \r or \n

                        then output the rspace value
                        #>
                        $options.RemoveTrailingLineEnding = $false
                    } else {
                        $options.RemoveTrailingLineEnding = $true
                    }



                    Write-Debug " Instruction is '$instruction'"
                    switch ($instruction) {
                        '=' {
                            <#
                            The EXPAND directive executes the code and outputs the result
                            #>
                            Write-Debug ' EXPAND'
                            $options.Type = 'expand'
                            $options.Start = $directiveStart
                            $options.Length = $directiveLength
                            $null = $templateTree.Add( ($code | New-TemplateElement @options) )
                            continue
                        }
                        '+' {
                            Write-Debug ' INCLUDE'
                            #TODO: Pass in a starting directory for the template includes
                            #TODO: Expand the string first so the user can do $HOME\my-header.pst1
                            #TODO: If I use the '+' how do i add the ability to remove the whitespace?
                            $options.Type = 'include'
                            $options.Start = $directiveStart
                            $options.Length = $directiveLength
                            $null = $templateTree.Add( ($code | New-TemplateElement @options) )
                            continue
                        }
                        '-' {
                            Write-Debug ' TRIM_START'
                            # $trimmed = $content -replace '(?smi)([\n\r]+|\A)[ \t]+\z', '$1'
                            $options.Type = 'content'
                            $options.Start = $contentStart
                            $options.Length = $contentLength
                            $options.RemoveLeadingWhitespace = $true
                            $null = $templateTree.Add( ($content | New-TemplateElement @options) )
                            $options.RemoveLeadingWhitespace = $false

                            $options.Type = 'code'
                            $options.Start = $directiveStart
                            $options.Length = $directiveLength

                            $null = $templateTree.Add( ($code | New-TemplateElement @options) )
                            continue
                        }
                        '' {
                            <#
                            CODEBLOCK: Block is executed but no value is inserted into the output
                            #>
                            Write-Debug " EXECUTE -`n code`n {$($code.Trim())}"
                            $options.Type = 'code'
                            $options.Start = $directiveStart
                            $options.Length = $directiveLength
                            $null = $templateTree.Add( ($code | New-TemplateElement @options) )
                        }
                        '#' {
                            Write-Debug ' COMMENT'
                        }
                    }
                }
                # advance the content "pointer" to the end of the directive
                $contentStart = $directiveStart + $directiveLength
            }
        }

        if ($contentStart -eq 0) {
            Write-Debug 'No matches found. Output the template'
            $options.Type = 'content'
            $options.Start = 0
            $options.Length = $Template.Length
            $null = $templateTree.Add( ($Template | New-TemplateElement @options) )
        } elseif ($contentStart -lt $Template.Length) {
            Write-Debug 'No more matches, but still text in the template'
            $options.Type = 'content'
            $options.Start = $contentStart
            $options.Length = $Template.Length - $contentStart
            $remainingContent = $Template.Substring($options.Start, $options.Length)
            $null = $templateTree.Add( ($remainingContent | New-TemplateElement @options) )
        }
    }
    end {

        $templateTree | Write-Output

        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
