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
        # $pattern = [regex]('(?sm)(?<lit><%%|%%>)|<%(?<ind>={1,2}|-|#)?(?<code>.*?)(?<tailch>[-=])?(?<!%)%>(?<rspace>[ \t]*\r?\n)?')
        $pattern = [regex]( -join (
                '(?sm)', # look for patterns across the whole string
                '(?<lit><%%|%%>)', # double '%' is used to "escape" template markers '<%%' => '<%' in output
                '|',
                '<%(?<ind>={1,2}|-|#)?', # start markers might have additional instructions '=', '-', or '#'
                '(?<code>.*?)', # the "code" inside the markers
                '(?<tailch>[-=])?', # end markers might have additional instructions '-', '='
                '(?<!%)%>', # "zero-width lookbehind '(?<!' for a '%' ')'" and match an end marker '%>'
                '(?<rspace>[ \t]*\r?\n)?')  # match the different types of whitespace at the end
        )
        $psGray = $PSStyle.Foreground.BrightBlack
        $psBlue = $PSStyle.Foreground.Blue
        $psReset = $PSStyle.Reset
    }
    process {
        Write-Debug "`n$('-' * 80)`n-- Process start $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
        $allMatches = $pattern.Matches( $Template )
        if ($allMatches.Count -gt 0) {
            Write-Output "$psGray Found $($allMatches.Count) matches$psReset"
            $count = 0

            <#
             "import" the data into the current session
            #>
            $Data.GetEnumerator() | ForEach-Object {
                New-Variable -Name $_.Key -Value $_.Value
            }

            foreach ($patternMatch in $allMatches) {
                $count++
                "$psGray $('-' * 20)`nThis is match $count`n$($foreach.Current.Value)`n$('-' * 20)$psReset"
                # value holds the match
                # content is the text in the Template that is between the last match and this one
                $contentLength = $patternMatch.Index - $position
                $content = $Template.Substring($position, $contentLength)

                #! move position to the point after the match for the next match
                $position = $patternMatch.Index + $patternMatch.Length
                #! if the user wanted to escape the markers, lit would be matched
                $literal = $patternMatch.Groups['lit']

                if ($literal.Success) {
                    if ($contentLength -ne 0) {
                        "Adding $content to Output"
                    }
                    switch ($literal.Value) {
                        '<%%' {
                            "Adding '<%' to Output"
                        }
                        '%%>' {
                            "Adding '%>' to Output"
                        }
                    }
                } else {
                    $ind = $patternMatch.Groups['ind'].Value
                    $code = $patternMatch.Groups['code'].Value
                    $tail = $patternMatch.Groups['tailch'].Value
                    $rspace = $patternMatch.Groups['rspace'].Value

                    if (($ind -ne '-') -and ($contentLength -ne 0)) {
                        "$psGray start marker did not have a '-' and content length is not 0$psReset"
                        "$psBlue Output content '$content'$psReset"
                    } else {
                        "$psGray start marker has a '-' and content length is 0$psReset"
                        "$psBlue Output code end ';'$psReset"
                    }
                    switch ($ind) {
                        '=' {
                            "$psGray start marker has a '='$psReset`n$psBlue Execute code {$($code.Trim())}$psReset"

                            try {
                                $sb = [scriptblock]::Create($code.Trim() )
                                $output = $sb.Invoke()
                            } catch {
                                $message = ( -join (
                                        'There was an error in the template at character ',
                                        $position,
                                        "`n",
                                        $foreach.Current.Value,
                                        "`n",
                                    ('~' * $foreach.Current.Value.Length),
                                        "`n",
                                        $_.ToString() -replace 'Exception calling "Invoke" with "0" argument\(s\):', ''

                                    ))
                                Write-Error $message -Category $_.CategoryInfo.Category
                                return
                            }
                            "$psBlue '$output'$psReturn"
                        }
                        '-' {
                            "$psGray start marker has a '-'$psReset`n$psBlue Output content after removing blank space '$($content -replace '(?smi)([\n\r]+|\A)[ \t]+\z', '$1')'$psReset"

                            "$psBlue Execute code {$($code.Trim())}$psReset"
                        }
                        '' {
                            "$psGray start marker has no additional marks$psReset`n$psBlue Execute code {$($code.Trim())}$psReset"
                        }
                        '#' {
                            "$psGray start marker has a '#' it's a comment$psReset"
                        }
                    }

                    if (($ind -ne '%') -and (($tail -ne '-') -or ($rspace -match '^[^\r\n]'))) {
                        <#
                        $ind is the char added to the start marker if any
                        $tail is the char added to the end marker if any

                        if the $ind isn't a percent (not sure how it could be based on the regex...)
                        and
                        $tail is not a '-' or the end of the match starts with something other \r or \n

                        then output the rspace vaue
                        #>
                        "ind is '$ind' and tail is '$tail'. Output rspace '$rspace'"
                    } else {
                        "output code end ';'"
                    }
                }
            }
        }

        if ($position -eq 0) {
            "No matches found. Output the template $Template"
        } elseif ($position -lt $Template.Length) {
            "No more matches, but still text in the template $($Template.Substring($position, $Template.Length - $position))"
        }


        Write-Debug "`n$('-' * 80)`n-- Process end $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
