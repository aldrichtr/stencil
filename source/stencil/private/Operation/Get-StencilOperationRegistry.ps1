
function Get-StencilOperationRegistry {
    [CmdletBinding()]
    param(
    )
    begin {
        Write-Debug "-- Begin $($MyInvocation.MyCommand.Name)"
    }
    process {
        if (-not(Test-StencilOperationRegistry)) {
            Write-Debug "  script registry not set.  Adding module variable StencilOperationRegistry"
            $script:StencilOperationRegistry = @{}
        }
    }
    end {
        Write-Debug "-- End $($MyInvocation.MyCommand.Name)"
        $script:StencilOperationRegistry
    }
}
