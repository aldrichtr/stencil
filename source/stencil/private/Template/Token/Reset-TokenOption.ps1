
function Reset-TokenOption {
    <#
    .SYNOPSIS
        Reset the options given to New-TemplateToken to their defaults.
    .DESCRIPTION
        This function is only useful inside `Convert-StringToToken`
    #>
    [CmdletBinding(
        SupportsShouldProcess
    )]
    param(
        # Optionally reset the content too
        [Parameter(
        )]
        [switch]$IncludeContent
    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    process {
        if ($PSCmdlet.ShouldProcess("Options", "Reset options to their defaults")) {
            $theOptions = $PSCmdlet.SessionState.PSVariable.Get('options')

            $theOptions.Value.Type = 'text'
            $theOptions.Value.Prefix = ''
            $theOptions.Value.Suffix = ''
            $theOptions.Value.Indent = ''
            $theOptions.Value.RemainingWhiteSpace = ''
            $theOptions.Value.RemoveIndent = $false
            $theOptions.Value.RemoveNewLine = $false
            $theOptions.Value.Index = ($theOptions.Value.Index + 1)
            if ($IncludeContent) {
                [void]$theOptions.Value.Content.Clear()
            }
            $PSCmdlet.SessionState.PSVariable.Set($theOptions)
        }
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
