
function Get-StateTable {
    <#
    .SYNOPSIS
        Get the current state table or create a new one if it does not exist
    #>
    [CmdletBinding()]
    param(
    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    process {
        if ($null -eq $script:__StateTable) {
            $script:__StateTable = New-StateTable
        }
        $script:__StateTable | Write-Output
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
