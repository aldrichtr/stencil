
function Expand-StencilValue {
    <#
    .SYNOPSIS
        Expand any variables in the given string
    .DESCRIPTION
        Expand-StencilValue will replace tokens in the given string with the variable value if found
    .EXAMPLE
        Expand-StencilValue "Hello ${env.UserName}"

        Hello Bob
    #>
    [CmdletBinding()]
    param(
        # The string to be expanded
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [string[]]$Value,

        # Optionally provide a data table to use in replacing variables
        [Parameter(
        )]
        [PSTypeName('Stencil.JobInfo')]$Data
    )
    begin {
        Write-Debug "-- Begin $($MyInvocation.MyCommand.Name)"
        $keyNotFound = $false
    }
    process {
        <#------------------------------------------------------------------
          There are multiple loops here:
          - First, the input ($Value) could be multi-line text, so we need to
            loop over each line.
          - In the current line, look for all the matches to the pattern
            '${}' and loop over each match
          - for this match, if the match was a multi-level value (i.e. env.foo)
            loop over each level


        ------------------------------------------------------------------#>
        if (-not($PSBoundParameters.ContainsKey('Data'))) {
            Write-Verbose '  No Job data given, using global Jobs Table'
            $Data = $script:Jobs # if no job config was given, use the "module's Jobs Table"
        }

        :line foreach ($line in $Value) {
            Write-Debug "  Looking for tokens in '$line'"
            # recursively look for tokens until none are found
            $result = $line | Select-String -Pattern '\$\{(?<var>.+?)\}' -AllMatches

            while ($result.Matches.Count -gt 0) {
                Write-Debug "   Found $($result.Matches.Count) tokens"
                $result.Matches | ForEach-Object {
                    $found = $_.Groups[0].Value
                    $var = $_.Groups[1].Value

                    Write-Debug "  Processing token '$found' as '$var'"
                    if ($var.IndexOf('.') -ge 0) {
                        Write-Debug "   '$var' is a multi-step key"
                        $parts = $var -split '\.'
                    } else {
                        $parts = @($var) # otherwise, just make a one-element array
                    }
                    Write-Debug "  '$var' has $($parts.count) levels"

                    $descend = $Data
                    $keyNotFound = $false # reset on each token
                    $level = 0
                    :key foreach ($part in $parts) {
                        $level++
                        Write-Debug "  Level #$level - Getting variable at '$part'"
                        Write-Debug "   $part parent object is a $($descend.GetType())"
                        <#------------------------------------------------------------------
                         As we "descend" down the Data object, the part may be an object,
                         table, array, etc.  We need to get down to the "last" part to
                         find that value so that we can associate the string '${env.foo.one}'
                         with the value in $Data.env.foo.one
                        ------------------------------------------------------------------#>
                        switch ($descend.GetType()) {
                            'Hashtable' {
                                if ($descend.Keys -contains $part) {
                                    Write-Debug "  HashTable: Found hashtable '$part'"
                                    Write-Debug "   Setting current descent to $($descend[$part])"
                                    $descend = $descend[$part]
                                } else {
                                    Write-Verbose "Warning: Key '$part' not found"
                                    $keyNotFound = $true
                                    break key
                                }
                            }
                            'PSCustomObject' {
                                if ($descend.psobject.properties.Name -contains $part) {
                                    Write-Debug "    Object: Found object property '$part'"
                                    $descend = $descend | Select-Object -ExpandProperty $part
                                    Write-Debug "     Setting current descent to $($descend.GetType()) $descend"
                                } else {
                                    Write-Verbose "Warning: Key '$part' not found"
                                    $keyNotFound = $true
                                    break key
                                }
                            }
                            'string' {
                                Write-Debug "  Found string value '$part'"
                                break key
                            }
                            Default {
                            }
                        } # switch
                    } # foreach part
                    if ($keyNotFound) {
                        Write-Verbose "  $found not found in input data"
                    } else {
                        $line = $line -replace [regex]::Escape($found) , $descend
                        Write-Debug "   Replacing token '$found'. Level #$level  line is now '$line'"
                    }
                } # end while
                $result = $line | Select-String -Pattern '\$\{(?<var>.+?)\}' -AllMatches
            Write-Debug "  final text after expansion '$line'"
        }
        # All tokens found have been replaced, output the line.  It may or may not have been changed
        $line
    }
}
end {
    Write-Debug "-- End $($MyInvocation.MyCommand.Name)"
}
}
