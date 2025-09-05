
function Move-Position {
    <#
    .SYNOPSIS
        Advance the pointer the given amount
    .EXAMPLE
        [ref]$cursor | Move-Position 2
    #>
    [CmdletBinding()]
    param(
        # The current value
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [ref]$Pointer,

        # The amount to advance
        [Parameter(
            Position = 0
        )]
        [int]$Value = 0
    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    process {
        $Pointer.Value = $Pointer.Value + $Value
        Write-Debug "Pointer now set to $($Pointer.Value)"
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
