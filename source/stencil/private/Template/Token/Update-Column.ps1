
function Update-Column {
    <#
    .SYNOPSIS
        Update the column value in Convert-StringToToken
    .DESCRIPTION
        This function is only useful within Convert-StringToToken.  This function gets the `column` value
        adds the `lexeme` length and then sets the `column` value to the new value.  This is done through the
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
        if ($PSCmdlet.ShouldProcess('column', 'Advance the column position')) {
            $theColumn = $PSCmdlet.SessionState.PSVariable.Get('column')
            if ($PSBoundParameters.ContainsKey('Count')) {
                Write-Debug '- Using Count parameter'
                $advance = $Count
            } else {
                $currentLexeme = ($PSCmdlet.SessionState.PSVariable.Get('lexeme').Value)
                $advance = $currentLexeme.Length
                Write-Debug '- Using lexeme length'
            }
            Write-Debug "Current column is : $($theColumn.Value)"
            $theColumn.Value = ($theColumn.Value + $advance)
            Write-Debug "After advancing : $($theColumn.Value)"

            $PSCmdlet.SessionState.PSVariable.Set($theColumn)
        }
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
