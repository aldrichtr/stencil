function ConvertFrom-StencilTemplate {
    <#
    .SYNOPSIS
        Converts Stencil Template text into a scriptblock
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        # The template text to execute
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [AllowEmptyString()]
        [string[]]$Template,

        # The data to supply to the template
        [Parameter(
        )]
        [hashtable]$Data

    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
        $startPosition = 0
        # $pattern = [regex]('(?sm)(?<lit><%%|%%>)|<%(?<instruction>={1,2}|-|#)?(?<code>.*?)(?<tailch>[-=])?(?<!%)%>(?<rspace>[ \t]*\r?\n)?')
        $templatePattern = [regex]( -join (
                '(?sm)', # look for patterns across the whole string
                '(?<lit><%%|%%>)', # double '%' is used to "escape" template markers '<%%' => '<%' in output
                '|',
                '<%(?<instr>={1,2}|-|\+|#)?', # start markers might have additional instructions: currently ('=', '-', '+' or '#')
                '(?<code>.*?)', # the "code" inside the markers
                '(?<tailch>[-=])?', # end markers might have additional instructions '-', '='
                '(?<!%)%>', # "zero-width lookbehind '(?<!' for a '%' ')'" and match an end marker '%>'
                '(?<rspace>[ \t]*\r?\n)?')  # match the different types of whitespace at the end
        )
        $collect = @()
        $output = [System.Text.StringBuilder]::new()
    }
    process {
        $collect += $Template
    }
    end {
        if ([string]::IsNullorEmpty($collect)) {
            Write-Verbose "No content was given"
            return
        } else {
            $templateContent = ($collect -join [System.Environment]::NewLine)
        }

        Write-Debug "Content is '$templateContent'"
        $allMatches = $templatePattern.Matches( $templateContent )
        if ($allMatches.Count -gt 0) {
            Write-Debug " Found $($allMatches.Count) matches"
            $count = 0

            <#
             "import" the data into the current session
            #>
            if (-not ([string]::IsNullorEmpty($Data))) {
                $Data.GetEnumerator() | ForEach-Object {
                    New-Variable -Name $_.Key -Value $_.Value
                }
            }

            foreach ($patternMatch in $allMatches) {
                $count++
                Write-Debug " $('-' * 20)`nThis is match $count`n$($foreach.Current.Value)`n$('-' * 20)"

                # content is the text in the Template that is between the last match and this one
                $contentLength = $patternMatch.Index - $startPosition
                $content = $templateContent.Substring($startPosition, $contentLength)

                #! move startPosition to the point after the match for the next match
                $startPosition = $patternMatch.Index + $patternMatch.Length
                #! if the user wanted to escape the markers, lit would be matched
                $literal = $patternMatch.Groups['lit']

                if ($literal.Success) {
                    <# BUG: This outputs the content twice

                    Template:
                    this should output the start marker <%%

                    this should output the end marker %%>

                    Output:
                    his should output the start marker A test template

                    this should output the start marker <%

                    this should output the end marker

                    this should output the end marker %>
                    #>
                    Write-Debug "found escape marker"
                    if ($contentLength -ne 0) {
                        $null = $output.Append($content)
                    }
                    switch ($literal.Value) {
                        '<%%' {
                            $null = $output.Append( '<%' )
                        }
                        '%%>' {
                            $null = $output.Append( '%>' )
                        }
                    }
                } else {
                    $instruction = $patternMatch.Groups['instr'].Value
                    $code = $patternMatch.Groups['code'].Value
                    $tail = $patternMatch.Groups['tailch'].Value
                    $rspace = $patternMatch.Groups['rspace'].Value
                    $code | ConvertFrom-TemplateString

                    if (($instruction -ne '-') -and ($contentLength -ne 0)) {
                        $null = $output.Append($content)
                    }


                    Write-Debug " Instruction is '$instruction'"
                    switch ($instruction) {
                        '=' {
                            <#
                            The EXPAND directive executes the code and outputs the result
                            #>
                            Write-Debug " EXPAND"
                            if (-not ([string]::IsNullorEmpty($expandedString))) {
                                $code | ConvertFrom-TemplateString
                                $result =  $code.Trim() | Invoke-StencilCodeBlock $foreach.Current.Value $startPosition
                                $null = $output.Append($result)
                            }
                        }
                        '+' {
                            Write-Debug " INCLUDE"
                            $possibleFileName = $code.Trim()
                            #TODO: Pass in a starting directory for the template includes
                            #TODO: Expand the string first so the user can do $HOME\my-header.pst1
                            $possiblePath = (Join-Path (Get-Location) $possibleFileName)

                            if ($null -ne $possiblePath) {
                                if (Test-Path $possiblePath) {
                                    $fileContent = Get-Content $possiblePath
                                    if ($null -ne $fileContent) {
                                        $null = $output.Append( $fileContent)
                                    }
                                }
                            }
                        }
                        '-' {
                            Write-Debug " TRIM_START"
                            $trimmed = $content -replace '(?smi)([\n\r]+|\A)[ \t]+\z', '$1'
                            $null = $output.Append($trimmed)
                            Write-Debug " EXECUTE -`n code`n {$($code.Trim())}"
                            $result = $code | Invoke-StencilCodeBlock $foreach.Current.Value $startPosition
                            $null = $output.Append($result)
                        }
                        '' {
                            <#
                            CODEBLOCK: Block is executed but no value is inserted into the output
                            #>
                            Write-Debug " EXECUTE -`n code`n {$($code.Trim())}"
                            $result = $code | Invoke-StencilCodeBlock $foreach.Current.Value $startPosition
                            $null = $output.Append($result)
                        }
                        '#' {
                            Write-Debug " COMMENT"
                        }
                    }

                    if (($instruction -ne '%') -and
                        (($tail -ne '-') -or ($rspace -match '^[^\r\n]'))) {
                        <#
                        $instruction is the char added to the start marker if any
                        $tail is the char added to the end marker if any

                        if the $instruction isn't a percent (not sure how it could be based on the regex...)
                        and
                        $tail is not a '-' or the end of the match starts with something other \r or \n

                        then output the rspace vaue
                        #>
                        $null = $output.Append($rspace)
                    }
                }
            }
        }

        if ($startPosition -eq 0) {
            Write-Debug "No matches found. Output the template"
             $null = $output.Append($templateContent)
        } elseif ($startPosition -lt $Template.Length) {
            Write-Debug "No more matches, but still text in the template"
             $remainingContent = $templateContent.Substring($startPosition, $templateContent.Length - $startPosition)
             $null = $output.Append($remainingContent)
        }

        $output.ToString()

        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
