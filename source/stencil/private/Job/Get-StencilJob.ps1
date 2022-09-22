
function Get-StencilJob {
    <#
    .SYNOPSIS
        Get the Job object from the Jobs collection
    #>
    [CmdletBinding()]
    param(
        # The Id of the job to retrieve
        [Parameter(
            Position = 0,
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [string]$Id
    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    process {
        $script:Jobs | Where-Object -Property 'Id' -EQ $Id
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
