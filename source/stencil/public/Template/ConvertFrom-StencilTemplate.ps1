
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
            if (-not ([string]::IsNullorEmpty($Data))) {
                if ($Data -is [hashtable]) {
                    $Data | Import-DataTable
                }
            }
            Convert-StringToToken -Template $Template | ForEach-Object {
                $token = $_
                if ($AstOnly.IsPresent) {
                    $token | Write-Output
                } else {
                    $token | Convert-TokenToTemplateInfo
                }
            }

        }
    } end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
