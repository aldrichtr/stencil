
function New-CommentToken {
    <#
    .SYNOPSIS
        Create a token representing a comment element
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
        if ($PSCmdlet.ShouldProcess('TokenInfo', 'Create Comment Token')) {
            $TokenInfo.Type       = 'CMNT'
            $TokenInfo.PSTypeName = 'Stencil.Template.CommentToken'
            $TokenInfo | Write-Output
        }
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
