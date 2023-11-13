
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
        $tokenPattern = '\$\{(?<var>.+?)\}'

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
        if (-not ($PSBoundParameters.ContainsKey('Data'))) {
            Write-Debug '  No Job data given, using global Jobs Table'
            throw "No data given for expanding stencil values"
        }

        :line foreach ($line in $Value) {
            Write-Debug "  Looking for tokens in '$line'"
            # recursively look for tokens until none are found

            while ( ($result = $line | Select-String -Pattern $tokenPattern -AllMatches ) ) {
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
                        Write-Debug "  Level #$level - looking for $part item of object [$($descend.GetType().FullName)]"
                        <#------------------------------------------------------------------
                         As we "descend" down the Data object, the part may be an object,
                         table, array, etc.  We need to get down to the "last" part to
                         find that value so that we can associate the string '${env.foo.one}'
                         with the value in $Data.env.foo.one
                         If the part is a number , then assume that is indexing an array
                        ------------------------------------------------------------------#>

                        :descend switch ($descend) {
                            {$_ -is [Hashtable]} {
                                if ($descend.Keys -contains $part) {
                                    Write-Debug "  HashTable: Found hashtable '$part'"
                                    Write-Debug "   Setting current descent to $($descend[$part])"
                                    $descend = $descend[$part]
                                    continue descend
                                } else {
                                    Write-Verbose "Warning: Key '$part' not found"
                                    $keyNotFound = $true
                                    break key
                                }
                            }
                            {$_ -is [PSCustomObject]} {
                                if ($descend.psobject.properties.Name -contains $part) {
                                    Write-Debug "    Object: Found object property '$part'"
                                    $descend = $descend | Select-Object -ExpandProperty $part
                                    Write-Debug "     Setting current descent to $($descend.GetType()) $descend"
                                    continue descend
                                } else {
                                    Write-Verbose "Warning: Key '$part' not found"
                                    $keyNotFound = $true
                                    break key
                                }
                            }
                            {($_ -is [Array]) -or
                             ($_ -is [System.Collections.ArrayList])} {
                                 if ($part -match '\d+') {
                                     $index = [int]($Matches.1)
                                     Write-Debug "    Array: Found array with $($descend.Count) items"
                                     if ($index -lt $descend.Count) {
                                        if ($null -ne $descend[$index]) {
                                            $descend = $descend[$index]
                                            continue descend
                                        } else {
                                            Write-Verbose "Warning: Key $part not found"
                                            $keyNotFound = $true
                                            break key
                                        }
                                    } else {
                                        Write-Verbose "Warning $index is greater than index of items"
                                        $keyNotFound = $true
                                        break key
                                    }
                                }
                            }
                            {$_ -is [string]} {
                                Write-Debug "  Found string value '$part'"
                                break key
                            }
                            Default {
                                continue descend

                            }
                        } # end switch
                    } # end foreach part
                    if ($keyNotFound) {
                        Write-Verbose "  $found not found in input data"
                    } else {
                        $line = $line -replace [regex]::Escape($found) , $descend
                        Write-Debug "   Replacing token '$found'. Level #$level  line is now '$line'"
                    }
                } # end foreach result result
                Write-Debug "  final text after expansion '$line'"
            } # end while result
            # All tokens found have been replaced, output the line.  It may or may not have been changed
            $ExecutionContext.InvokeCommand.ExpandString($line) | Write-Output
        } # end foreach line
    }
    end {
        Write-Debug "-- End $($MyInvocation.MyCommand.Name)"
    }
}
