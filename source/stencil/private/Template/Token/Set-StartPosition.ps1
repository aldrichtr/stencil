
function Set-StartPosition {
    <#
    .SYNOPSIS
        Set the Start position options in Convert-StringToToken
    #>
    [CmdletBinding()]
    param(
        # A reference to the options table
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [ref]$Options,

        # The Cursor position (index of the cursor)
        [Parameter(
        )]
        [int]$Index,

        # The Line Number
        [Parameter(
        )]
        [int]$Line,

        # The column number
        [Parameter(
        )]
        [int]$Column
    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    process {

        if ($PSBoundParameters.ContainsKey('Index')) {
            $Options.Value['Start'].Index = $Index
            Write-Debug "Set Index to $Index"
        }
        if ($PSBoundParameters.ContainsKey('Line')) {
            $Options.Value['Start'].Line = $Line
            Write-Debug "Set Line to $Line"
        }
        if ($PSBoundParameters.ContainsKey('Column')) {
            $Options.Value['Start'].Column = $Column
            Write-Debug "Set Column to $Column"
        }
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
