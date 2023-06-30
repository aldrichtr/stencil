function Import-DataTable {
    <#
    .SYNOPSIS
        Import the variables and values defined in the Metadata table
    #>
    [CmdletBinding()]
    param(
        # The metadata table
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [hashtable]$Data
    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    process {
        Write-Debug "`n$('-' * 80)`n-- Process start $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
        if (-not ([string]::IsNullorEmpty($Data))) {
            $Data.GetEnumerator() | ForEach-Object {
                if ($null -ne (Get-Variable $_.Key -ErrorAction SilentlyContinue)) {
                    Set-Variable -Name $_.Key -Value $_.Value
                } else {
                    New-Variable -Name $_.Key -Value $_.Value -Scope 'Script' # == module scope
                }
            }
        }

        Write-Debug "`n$('-' * 80)`n-- Process end $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
