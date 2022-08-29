
function Reset-StencilOperationRegistry {
    [CmdletBinding()]
    param(
    )
    begin {
        Write-Debug "-- Begin $($MyInvocation.MyCommand.Name)"
    }
    process {
        $script:StencilOperationRegistry = @{}
    }
    end {
        Write-Debug "-- End $($MyInvocation.MyCommand.Name)"
    }
}
