function Update-Cursor {
    <#
    .SYNOPSIS
        Update the cursor value in Convert-StringToToken
    .DESCRIPTION
        This function is only useful within Convert-StringToToken.  This function gets the `cursor` value
        adds the `lexeme` length and then sets the `cursor` value to the new value.  This is done through the
        SessionState
    #>
    [CmdletBinding()]
    param(
    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    process {
        $theCursor = $PSCmdlet.SessionState.PSVariable.Get('cursor')
        $currentLexeme = ($PSCmdlet.SessionState.PSVariable.Get('lexeme').Value)
        Write-Debug "Current cursor is : $($theCursor.Value)"
        $theCursor.Value = ($theCursor.Value + $currentLexeme.Length)
        Write-Debug "After adding lexeme length : $($theCursor.Value)"

        $PSCmdlet.SessionState.PSVariable.Set($theCursor)
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
