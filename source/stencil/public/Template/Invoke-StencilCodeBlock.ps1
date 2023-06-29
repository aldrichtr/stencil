function Invoke-StencilCodeBlock {
    <#
    .SYNOPSIS
        Execute the given code block and return the result
    .EXAMPLE
        $code | Invoke-StencilCodeBlock '<%= $Greeting %>' 4
    #>
    [CmdletBinding()]
    param(
        # The Code block to execute
        [Parameter(
            Mandatory,
            Position = 2,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [string]$CodeBlock,

        # The original position in the template
        [Parameter(
            Mandatory,
            Position = 1,
            ValueFromPipeline
        )]
        [int]$Position,

        # The original template string
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipelineByPropertyName
        )]
        [string]$Directive
    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    process {
        Write-Debug "`n$('-' * 80)`n-- Process start $($MyInvocation.MyCommand.Name)`n$('-' * 80)"

        try {
            Write-Debug "The code block is '$CodeBlock' at position $Position and the Directive is '$Directive'"
            $sb = [scriptblock]::Create($CodeBlock.Trim() )
            $output = $sb.Invoke()
        } catch {
            $message = ( -join (
                    'There was an error in the template at character ',
                    $Position,
                    "`n",
                    $Directive,
                    "`n",
                                    ('~' * $Directive.Length),
                    "`n",
                    $_.ToString() -replace 'Exception calling "Invoke" with "0" argument\(s\):', ''

                ))
            Write-Error $message -Category $_.CategoryInfo.Category
            return
        }
        $output

        Write-Debug "`n$('-' * 80)`n-- Process end $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
