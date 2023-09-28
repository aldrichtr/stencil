
function New-TextToken {
    <#
    .SYNOPSIS
        Create a Stencil.Template.TextToken object
    #>
    [CmdletBinding(
        SupportsShouldProcess
    )]
    param(
        # The tokeninfo table
        [Parameter(
            ValueFromPipeline
        )]
        [hashtable]$TokenInfo

    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    process {
        if ($PSCmdlet.ShouldProcess("TokenInfo", "Create TextToken")) {

        }
        # No processing of a Text block at this time
        $TokenInfo.PSTypeName = 'Stencil.Template.TextToken'
        $TokenInfo | Write-Output
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
