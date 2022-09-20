
function Test-StencilJob {
    [CmdletBinding()]
    param(
        # The Job Id to test
        [Parameter(
            Position = 0,
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [string]$Id
    )
    begin {
        Write-Debug "-- Begin $($MyInvocation.MyCommand.Name)"
    }
    process {
        (($script:Jobs | Where-Object -Property 'Id' -EQ $Id).Count -gt 0)
    }
    end {
        Write-Debug "-- End $($MyInvocation.MyCommand.Name)"
    }
}
