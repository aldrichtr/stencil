
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
        # The options hashtable. Passed by reference
        [Parameter(
            ValueFromPipeline
        )]
        [ref]$Options,

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
            $Options.Value.Type = 'text'
            $Options.Value.Prefix = ''
            $Options.Value.Suffix = ''
            $Options.Value.Indent = ''
            $Options.Value.Order = ($Options.Value.Order + 1)
            $Options.Value.Start = 0
            if ($IncludeContent) {
                [void]$Options.Value.Content.Clear()
            }
        }
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
