
function Convert-DirectiveParameter {
    <#
    .SYNOPSIS
        Extract the parameters in a directive line and return them and the remaining content
    #>
    [CmdletBinding()]
    param(
        # The content of the directive
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [string]$Content
    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    process {
        Write-Debug "`n$('-' * 80)`n-- Process start $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
        $splitOptions = [StringSplitOptions]::RemoveEmptyEntries + [StringSplitOptions]::TrimEntries
        $parts = [ArrayList]::new($Content.Split(' ', $splitOptions))
        #TODO: Extracting the parameters needs to be pulled up into it's own function
        # I could do something like send the content to `Format-ContentParameters` and then
        # return a hash with a 'Parameters' key and a 'Content' key which would be the remaining
        $parameters = @{}
        $toBeRemoved = @()

        foreach ($part in $parts) {
            if ($part.StartsWith('-')) {
                Write-Debug "$part is a parameter"
                $partIndex = $parts.IndexOf($part)
                $nextIndex = $partIndex + 1
                $nextValue = $parts[$nextIndex]

                $parameterName = $part.Remove(0, 1)
                if ($nextIndex -le $parts.Count) {
                    # The next item in the list is not another parameter
                    if ($nextValue.StartsWith('-')) {
                        $parameters.Add($parameterName, $true)
                    } else {
                        $parameters.Add($parameterName, $nextValue)
                        $toBeRemoved += $nextValue
                    }
                } else {
                    $parameters.Add($parameterName, $true)
                }
                $toBeRemoved += $part
            }
        }

        foreach ($word in $toBeRemoved) { $null = $parts.Remove($word) }
        Write-Debug "Parameters are : $($parameters | ConvertTo-Json)"
        if ($parts[0] -like 'include') {
            Write-Debug "We did receive a $($parts[0]) directive"
            $null = $parts.RemoveAt(0)
            Write-Debug "Removed.  The next part is $($parts[0])"
        } else {
            Write-Debug "Must have been using the '+' key"
            Write-Debug "The next part is $($parts[0])"
        }

        $return = @{
            Parameters = $parameters
            Content = ($parts -join ' ')
        }

        [PSCustomObject]$return | Write-Output
        Write-Debug "`n$('-' * 80)`n-- Process end $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
