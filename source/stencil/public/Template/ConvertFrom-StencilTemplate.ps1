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

        )]
        [string[]]$Template,

        # The data to supply to the template
        [Parameter(
        )]
        [hashtable]$Data

    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
        $position = 0
        # $pattern = [regex]('(?sm)(?<lit><%%|%%>)|<%(?<instruction>={1,2}|-|#)?(?<code>.*?)(?<tailch>[-=])?(?<!%)%>(?<rspace>[ \t]*\r?\n)?')
        $pattern = [regex]( -join (
                '(?sm)', # look for patterns across the whole string
                '(?<lit><%%|%%>)', # double '%' is used to "escape" template markers '<%%' => '<%' in output
                '|',
                '<%(?<instr>={1,2}|-|\+|#)?', # start markers might have additional instructions: currently ('=', '-', '+' or '#')
                '(?<code>.*?)', # the "code" inside the markers
                '(?<tailch>[-=])?', # end markers might have additional instructions '-', '='
                '(?<!%)%>', # "zero-width lookbehind '(?<!' for a '%' ')'" and match an end marker '%>'
                '(?<rspace>[ \t]*\r?\n)?')  # match the different types of whitespace at the end
        )
    }
    process {
        Write-Debug "`n$('-' * 80)`n-- Process start $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
        $allMatches = $pattern.Matches( $Template )
        if ($allMatches.Count -gt 0) {
            Write-Debug " Found $($allMatches.Count) matches"
            $count = 0

            <#
             "import" the data into the current session
            #>
            $Data.GetEnumerator() | ForEach-Object {
                New-Variable -Name $_.Key -Value $_.Value
            }

            foreach ($patternMatch in $allMatches) {
                $count++
                Write-Debug " $('-' * 20)`nThis is match $count`n$($foreach.Current.Value)`n$('-' * 20)"

                # content is the text in the Template that is between the last match and this one
                $contentLength = $patternMatch.Index - $position
                $content = $Template.Substring($position, $contentLength)

                #! move position to the point after the match for the next match
                $position = $patternMatch.Index + $patternMatch.Length
                #! if the user wanted to escape the markers, lit would be matched
                $literal = $patternMatch.Groups['lit']

                if ($literal.Success) {
                    Write-Debug "found escape marker"
                    if ($contentLength -ne 0) {
                        $content
                    }
                    switch ($literal.Value) {
                        '<%%' {
                            '<%'
                        }
                        '%%>' {
                            '%>'
                        }
                    }
                } else {
                    $instruction = $patternMatch.Groups['instr'].Value
                    $code = $patternMatch.Groups['code'].Value
                    $tail = $patternMatch.Groups['tailch'].Value
                    $rspace = $patternMatch.Groups['rspace'].Value

                    if (($instruction -ne '-') -and ($contentLength -ne 0)) {
                        Write-Debug "start marker did not have a '-' and content length is not 0"
                        $content
                    }

                    Write-Debug " Instruction is '$instruction'"
                    switch ($instruction) {
                        '=' {
                            Write-Debug " EXPAND"
                            $expandedString = $PSCmdlet.InvokeCommand.ExpandString( $code.Trim() )
                            if (-not ([string]::IsNullorEmpty($expandedString))) {
                                $expandedString | Invoke-StencilCodeBlock $foreach.Current.Value $position
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
                                        $fileContent
                                    }
                                }
                            }
                        }
                        '-' {
                            Write-Debug " TRIM_START"
                            $content -replace '(?smi)([\n\r]+|\A)[ \t]+\z', '$1'
                            Write-Debug " EXECUTE -`n code`n {$($code.Trim())}"
                            $code | Invoke-StencilCodeBlock $foreach.Current.Value $position
                        }
                        '' {
                            <#
                             CODEBLOCK: Block is executed but no value is inserted into the output
                            #>
                            Write-Debug " EXECUTE -`n code`n {$($code.Trim())}"
                            $code | Invoke-StencilCodeBlock $foreach.Current.Value $position
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
                        Write-Debug "instruction is '$instruction' and tail is '$tail'. Output rspace '$rspace'"
                    } else {
                        Write-Debug "output code end ';'"
                    }
                }
            }
        }

        if ($position -eq 0) {
            Write-Debug "No matches found. Output the template"
             $Template
        } elseif ($position -lt $Template.Length) {
            Write-Debug "No more matches, but still text in the template"
             "$($Template.Substring($position, $Template.Length - $position))"
        }


        Write-Debug "`n$('-' * 80)`n-- Process end $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
