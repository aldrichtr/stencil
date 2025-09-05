
function Convert-DirectiveParameter {
    <#
    .SYNOPSIS
        Extract the parameters in a string and return them as a hashtable
    .EXAMPLE
        $parameters = $tokenInfo | Convert-DirectiveParameter
    .EXAMPLE
        $tokenInfo | Convert-DirectiveParameter

        Converts the parameters and adds them to the tokenInfo Parameters
    #>
    [CmdletBinding()]
    param(
        # The content of the directive
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [ref]$TokenInfo

    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    process {
        if ([string]::IsNullorEmpty($TokenInfo.Value.Content)) {
            Write-Verbose 'Token has no content to convert parameters from'
            return $null
        } else {
            $originalContent = $TokenInfo.Value.Content.ToString()

            $paramIndex = $originalContent.IndexOf(' -')
            if ($paramIndex -ge 0) {
                $parameterPart = $originalContent.Substring($paramIndex)
                $contentPart = $originalContent.Substring(0, $paramIndex)
                Write-Debug "TokenInfo content may contain parameters (found '-' character)"
                Write-Debug "Content: '$contentPart' :: Parameters: '$parameterPart'"
            }
            $splitOptions = [StringSplitOptions]::RemoveEmptyEntries + [StringSplitOptions]::TrimEntries
            $parts = $parameterPart.Split('-', $splitOptions)

            foreach ($part in $parts) {
                Write-Debug "This part is: $part"
                $firstSpace = $part.IndexOf(' ')
                if ($firstSpace -ge 0) {
                    $parameterName = $part.Substring(0,$firstSpace).Trim()
                    $parameterValue = $part.Substring($firstSpace).Trim()
                } else {
                    $parameterName = $part
                    $parameterValue = $true
                }
                Write-Debug "Parameter: $parameterName => $parameterValue"
            }
        }
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
