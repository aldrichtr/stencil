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
        $scriptBody = [System.Text.StringBuilder]::new()
        $blockContent = [System.Text.StringBuilder]::new()
    }
    process {
        Write-Debug "`n$('-' * 80)`n-- Process start $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
        foreach ($element in $Tree) {
            Write-Debug "Process $($element.Type) element index = $($Tree.IndexOf($element))"
            switch ($element.Type) {
                'content' {
                    if ($state -ne [ElementState]::BLOCK) {
                        $directive = ( @(
                                '@"',
                                $element.Content,
                                '"@',
                                [System.Environment]::NewLine
                            ) -join [System.Environment]::NewLine
                        )
                        continue
                    } else {
                        $blockContent.Append($element.Content)
                    }
                }
                'code' {
                    $firstWord = ($element.Content.Trim() -split ' ')[0]
                    switch ( $firstWord ) {
                        'block' {
                            $blockContent.AppendLine($element.Content)
                            $state = [ElementState]::BLOCK
                            continue
                        }
                        'end' {
                            if ($state -eq [ElementState]::BLOCK) {
                                $blockContent.AppendLine($element.Content)
                                $directive = $blockContent.ToString() | New-BlockDirective
                                $state = [ElementState]::NONE
                                continue
                            }
                        }
                        default {
                            $directive = $element | ConvertTo-TemplateDirective
                            continue
                        }
                    }
                    continue

                }
                'include' {
                    $directive = $element | New-IncludeDirective
                    continue
                }
            }
            $null = $scriptBody.Append($directive)
        }


        Write-Debug "`n$('-' * 80)`n-- Process end $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    end {
        Write-Debug "Creating ScriptBlock from $($scriptBody.ToString())"
        $compiledTemplate = [scriptblock]::Create($scriptBody.ToString())

        $compiledTemplate | Write-Output

        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
