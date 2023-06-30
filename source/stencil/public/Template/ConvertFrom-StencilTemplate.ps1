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
        [string[]]$Template,

        # The data to supply to the template
        [Parameter(
        )]
        [hashtable]$Data

    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
        $collect = @()
    }
    process {
        <#
        Because we can have the template content come in from the pipeline (which would be one line at a time) or
        as an array of one or more lines from the parameter, we collect it all here to be used in the `end` block
        #>
        $collect += $Template
    }
    end {

        if ([string]::IsNullorEmpty($collect)) {
            Write-Verbose 'No content was given'
            return
        } else {
            Write-Debug "Processing $($collect.Count) lines in template"
            $templateContent = ($collect -join [System.Environment]::NewLine)
        }
        $syntaxTree = Convert-StringToTemplateTree -Template $templateContent -Data:$Data

#        $syntaxTree | Select-Object Name, Type, Start, Length, RemoveLeading, RemoveTrailing, Content, Data | ConvertTo-Json
        Convert-TreeToTemplateInfo -Tree $syntaxTree

        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
