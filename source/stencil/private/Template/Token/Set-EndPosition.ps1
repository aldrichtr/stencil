
function Set-EndPosition {
    <#
    .SYNOPSIS
        Set the End position options in Convert-StringToToken
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

        $theOptions.Value.End.Index = $currentCursor
        $theOptions.Value.End.Column = $currentColumn
        $theOptions.Value.End.Line = $currentLine


        Write-Debug "Setting End Index => $currentCursor"
        Write-Debug "Setting End Column => $currentColumn"
        Write-Debug "Setting End Line => $currentLine"

        $PSCmdlet.SessionState.PSVariable.Set($theOptions)

    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
