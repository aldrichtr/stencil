
function New-TemplateBlock {
    <#
    .SYNOPSIS
        Create a new 'Stencil.TemplateBlock' object
    #>
    [OutputType('Stitch.TemplateBlock')]
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'low'
    )]
    param(
        # The name of the block
        [Parameter(
            Mandatory
        )]
        [string]$Name,

        # The starting position of the template block in the original content
        [Parameter(
        )]
        [int]$Start,

        # The ending position of the template block in the original content
        [Parameter(
        )]
        [int]$End,

        # Metadata associated with the template block
        [Parameter(
        )]
        [hashtable]$Data
    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    process {
        Write-Debug "`n$('-' * 80)`n-- Process start $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
        $blockContent = [System.Collections.Generic.List[Object]]::new()

        if ($PSCmdlet.ShouldProcess($Name, "Create new Stitch.TemplateBlock")) {

        }
        Write-Debug "`n$('-' * 80)`n-- Process end $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
