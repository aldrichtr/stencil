
using namespace System.Text
function ConvertTo-TemplateElement {
    <#
    .SYNOPSIS
        Convert a list of TemplateElements to a scriptblock
    #>
    [CmdletBinding()]
    param(
        # The list of tokens
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [PSTypeName('Stencil.Template.Token')][Object[]]$InputObject
    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
        $config = Import-Configuration
        | Select-Object -ExpandProperty 'Template'

        # As tokens are processed, Create the block of text that will become the scriptblock.

        $text = [stringbuilder]::new()
        $param = [stringbuilder]::new()
        [void]$param.Append('param (')
    }
    process {
        foreach ($token in $InputObject) {
            #! Using PSTypeName vice Type
            $tokenType = $token.PSTypeNames[0].Split('.')
            | Select-Object -Last 1

            Write-Debug "This token is type $tokenType"
            switch ($tokenType) {
                'TextToken' {
                    Write-Debug 'Adding Text element'
                    if (-not ([string]::IsNullorEmpty($token.Content))) {
                        Write-Debug "Token content: '$($token.Content)'"
                        $inner = (-join @(
                                '"',
                                ($token.Content -replace '"', '`"'),
                                '"',
                                ' | Write-Output'
                            ))
                        Write-Debug "- Block text is [$inner]"
                        [void]$text.Append($inner)
                    }
                }
                'FrontMatterToken' {
                    if (-not ([string]::IsNullorEmpty($token.YAML))) {
                        if ($null -ne $config.FrontMatter.Options) {
                            $parserOptions = $config.FrontMatter.Options
                            $fm = $token.YAML | ConvertFrom-Yaml @parserOptions
                        } else {
                            $fm = $token.YAML | ConvertFrom-Yaml
                        }

                        if ($null -ne $fm) {
                            foreach ($p in $fm.GetEnumerator()) {}
                        }
                    }
                }
            }

            #! Only produce output if a 'Block' was created
            if ($null -ne $elementObject) {
                $elementObject.PSTypeNames.Insert(1, 'Stencil.Template.Element')
                $elementObject | Add-Member -MemberType ScriptMethod -Name 'Invoke' -Value {
                    $this.Block.Invoke()
                }
                $elementObject | Write-Output
            }
        }
    }
    end {

        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
