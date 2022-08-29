
function Get-StencilOperationCommand {
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
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    process {
        if ($Name | Test-StencilOperation) {
            $operation = $script:StencilOperationRegistry[$Name]
            $operation.Command | Write-Output
        } else {
            throw "Operation '$Name' not registered"
        }
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
