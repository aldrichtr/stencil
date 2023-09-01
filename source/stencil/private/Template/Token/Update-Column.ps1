function Update-Column {
    <#
    .SYNOPSIS
        Update the column value in Convert-StringToToken
    .DESCRIPTION
        This function is only useful within Convert-StringToToken.  This function gets the `column` value
        adds the `lexeme` length and then sets the `column` value to the new value.  This is done through the
        SessionState
    #>
    [CmdletBinding()]
    param(
    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    process {
        $theColumn = $PSCmdlet.SessionState.PSVariable.Get('column')
        $currentLexeme = ($PSCmdlet.SessionState.PSVariable.Get('lexeme').Value)
        Write-Debug "Current column is : $($theColumn.Value)"
        $theColumn.Value = ($theColumn.Value + $currentLexeme.Length)
        Write-Debug "After adding lexeme length : $($theColumn.Value)"

        $PSCmdlet.SessionState.PSVariable.Set($theColumn)
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
