
function Get-StencilOperationRegistry {
    [CmdletBinding()]
    param(
    )
    begin {
        Write-Debug "-- Begin $($MyInvocation.MyCommand.Name)"
    }
    process {
        if ($null -eq $script:StencilOperationRegistry) {
            Write-Debug "  script registry not set.  Adding module variable StencilOperationRegistry"
            $script:StencilOperationRegistry = @{}
        }
    }
    end {
        Write-Debug "-- End $($MyInvocation.MyCommand.Name)"
        $script:StencilOperationRegistry
    }
}
