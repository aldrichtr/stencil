
function Update-Cursor {
    <#
    .SYNOPSIS
        Update the cursor value in Convert-StringToToken
    .DESCRIPTION
        This function is only useful within Convert-StringToToken.  This function gets the `cursor` value
        adds the `lexeme` length and then sets the `cursor` value to the new value.  This is done through the
        SessionState
    #>
    [CmdletBinding(
        SupportsShouldProcess
    )]
    param(
        # A number of characters to advance.  Defaultes to lexeme length
        [Parameter(
        )]
        [int]$Count
    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    process {
        if ($PSCmdlet.ShouldProcess('cursor', 'Advance the cursor position')) {
            $theCursor = $PSCmdlet.SessionState.PSVariable.Get('cursor')
            if ($PSBoundParameters.ContainsKey('Count')) {
                Write-Debug "- Using Count parameter"
                $advance = $Count
            } else {
                $currentLexeme = ($PSCmdlet.SessionState.PSVariable.Get('lexeme').Value)
                $advance = $currentLexeme.Length
                Write-Debug "- Using lexeme length"
            }
            Write-Debug "Current cursor is : $($theCursor.Value)"
            $theCursor.Value = ($theCursor.Value + $advance)
            Write-Debug "After advancing : $($theCursor.Value)"

            $PSCmdlet.SessionState.PSVariable.Set($theCursor)
        }
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
