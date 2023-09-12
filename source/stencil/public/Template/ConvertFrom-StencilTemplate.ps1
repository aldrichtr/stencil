
function ConvertFrom-StencilTemplate {
    <#
    .SYNOPSIS
        Converts Stencil Template text into a scriptblock
    #>
    [OutputType([string])]
    [CmdletBinding(
    )]
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
        [switch]$AstOnly,

        # A reference to a variable to load the tokens to
        [Parameter(
            DontShow
        )]
        [ref]$Tokens

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
                    $Data
                    | Import-DataTable
                }
            }
            Convert-StringToToken -Template $Template
            | ForEach-Object {
                $token = $_
                if ($null -ne $Tokens) {
                    $Tokens.Value += $token
                    | Write-Output
                }
                $ast = $token
                | ConvertTo-TemplateElement


                if ($AstOnly) {
                    $ast
                    | Write-Output
                } else {
                    #TODO: Probably want to create a top level object that would recursively invoke all below
                    $ast
                    | ForEach-Object {
                        $_.Invoke()
                    }
                }
            }

        }
    } end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
