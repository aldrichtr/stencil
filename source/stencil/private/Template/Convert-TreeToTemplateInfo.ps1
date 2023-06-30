function Convert-TreeToTemplateInfo {
    <#
    .SYNOPSIS
        Convert a list of TemplateElements to a scriptblock
    #>
    [CmdletBinding()]
    param(
        # The "AST" of Elements from the template
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [System.Collections.Generic.List[Object]]$Tree
    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
        enum ElementState {
            NONE
            METADATA
            CONTENT
            BLOCK
        }
        $state = [ElementState]::NONE
        $sb = [System.Text.StringBuilder]::new()
    }
    process {
        Write-Debug "`n$('-' * 80)`n-- Process start $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
        foreach ($element in $Tree) {
            Write-Debug "Process $($element.Type) element index = $($Tree.IndexOf($element))"
            switch ($element.Type) {
                'content' {
                    if ($state -ne [ElementState]::BLOCK) {
                        $directive = "Write-Output @`"`n$($element.Content)`n`"@"
                        continue
                    }
                }
                'code' {
                    $directive = $element | ConvertTo-TemplateDirective
                    continue
                }
                'include' {
                    $directive = $element | New-IncludeDirective
                    continue
                }
            }
            $null = $sb.Append($directive)
        }


        Write-Debug "`n$('-' * 80)`n-- Process end $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    end {
        $compiledTemplate = [scriptblock]::Create($sb.ToString())

        $compiledTemplate | Write-Output

        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
