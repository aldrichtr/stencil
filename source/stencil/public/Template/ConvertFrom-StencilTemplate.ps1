
function ConvertFrom-StencilTemplate {
    <#
    .SYNOPSIS
        Converts Stencil Template text into a scriptblock
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        # The template text to execute
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [AllowEmptyString()]
        [string]$Template,

        # The data to supply to the template
        [Parameter(
        )]
        [hashtable]$Data,

        # Return just the AST
        [Parameter(
            DontShow
        )]
        [switch]$AstOnly

    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    process {
        if ([string]::IsNullorEmpty($Template)) {
            Write-Verbose 'No content was given'
            return
        } else {
            Write-Debug "Template is $($Template.Length) characters"
            $tokens = Convert-StringToToken -Template $Template
        }

        if ($AstOnly.IsPresent) {
            $tokens
        } else {
            Convert-TreeToTemplateInfo -Tree $syntaxTree
        }
    } end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
