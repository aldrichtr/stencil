
function ConvertFrom-TemplateString {
    <#
    .SYNOPSIS
        Convert the template string into a Stencil.TemplateBlock
    #>
    [CmdletBinding()]
    param(
        # The template string to convert
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [string]$Template
    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
        $templateDirectives = Get-TemplateDirective
    }
    process {
        Write-Debug "`n$('-' * 80)`n-- Process start $($MyInvocation.MyCommand.Name)`n$('-' * 80)"

        Write-Output "Received template '$Template'"
        $firstWord = ($Template.Trim() -split ' ')[0]
        if ( $firstWord.ToLower() -iin $templateDirectives.Keys) {
            Write-Output "Found directive $firstWord"
        }


        Write-Debug "`n$('-' * 80)`n-- Process end $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
