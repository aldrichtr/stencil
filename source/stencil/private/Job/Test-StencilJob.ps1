
function Test-StencilJob {
    [CmdletBinding()]
    param(
        # The operation to lookup
        [Parameter(
            Position = 0,
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [string]$Name
    )
    begin {
        Write-Debug "-- Begin $($MyInvocation.MyCommand.Name)"
    }
    process {
        (($script:Jobs | Where-Object -Property 'Name' -EQ $Name).Count -gt 0)
    }
    end {
        Write-Debug "-- End $($MyInvocation.MyCommand.Name)"
    }
}
