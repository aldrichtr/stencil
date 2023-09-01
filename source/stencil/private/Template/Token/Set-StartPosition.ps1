
function Set-StartPosition {
    <#
    .SYNOPSIS
        Set the Start position options in Convert-StringToToken
    #>
    [CmdletBinding()]
    param(
    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    process {
        $theOptions = $PSCmdlet.SessionState.PSVariable.Get('options')
        $currentCursor = $PSCmdlet.SessionState.PSVariable.Get('cursor').Value
        $currentColumn = $PSCmdlet.SessionState.PSVariable.Get('column').Value
        $currentLine = $PSCmdlet.SessionState.PSVariable.Get('lineNumber').Value

        $theOptions.Value.Start.Index = $currentCursor
        $theOptions.Value.Start.Column = $currentColumn
        $theOptions.Value.Start.Line = $currentLine

        Write-Debug "Setting Start Index => $currentCursor"
        Write-Debug "Setting Start Column => $currentColumn"
        Write-Debug "Setting Start Line => $currentLine"
        $PSCmdlet.SessionState.PSVariable.Set($theOptions)

    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
