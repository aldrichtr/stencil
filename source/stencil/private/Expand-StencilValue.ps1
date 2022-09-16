
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
        [System.Object]$Data
    )
    begin {
        Write-Debug "-- Begin $($MyInvocation.MyCommand.Name)"
        $key_not_found = $false
    }
    process {
        if (-not($PSBoundParameters.ContainsKey('Data'))) {
            $Data = $script:Jobs # if no job config was given, use the "module's Jobs Table"
        }
        $debug_string = "`n$('-' * 80)`n Data:"
        $debug_string += (
            Convert-SamplerHashtableToString -Hashtable $Data) -replace '\{', "{`n" -replace ';', "`n" -replace '\}', "`n}"
        $debug_string += "`n$('-' * 80)"
        Write-Debug $debug_string
        :line foreach ($line in $Value) {
            Write-Debug "  Looking for tokens in '$line'"
            $result = $line | Select-String -Pattern '\$\{(?<var>.+?)\}' -AllMatches
            if ($result.Matches.Count -gt 0) {
                Write-Debug "   Found $($result.Matches.Count) tokens"
                $result.Matches | ForEach-Object {
                    $found = $_.Groups[0].Value
                    $var = $_.Groups[1].Value

                    Write-Debug "  Processing token '$found' as '$var'"
                    if ($var.IndexOf('.')) {
                        Write-Debug "   '$var' is a path"
                        $parts = $var -split '\.'
                        $descend = $Data
                        $key_not_found = $false # reset on each token
                        :key foreach ($part in $parts) {
                            if ($descend.Keys -contains $part) {
                                Write-Debug "  Found level '$part'"
                                Write-Debug "   it's value is $($descend[$part])"
                                $descend = $descend[$part]
                            } else {
                                Write-Warning "Key '$part' not found"
                                $key_not_found = $true
                                break key
                            }
                        }
                    }

                    if ($key_not_found) {
                        Write-Warning "'$found' is not a valid variable"
                    } else {
                        if (-not($descend -is [hashtable])) {
                            $line = $line -replace [regex]::Escape($found) , $descend
                        } else {
                            Write-Warning "  '$found' is a table not a value"
                        }
                    }
                }
            } else {
                Write-Debug "  No tokens found in '$line'"
            }
            # All tokens found have been replaced, output the line.  It may or may not have been changed
            Write-Debug "  final text after expansion '$line'"
            $line
        }
    }
    end {
        Write-Debug "-- End $($MyInvocation.MyCommand.Name)"
    }
}
