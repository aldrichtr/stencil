
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
    }
    process {
        foreach ($token in $InputObject) {
            $tokenType = $token.PSTypeNames[0].Split('.')
            | Select-Object -Last 1
            Write-Debug "This token is type $tokenType"
            $element = @{
                Start = $token.Start
                End   = $token.End
                Index = $token.Index
            }
            switch ($tokenType) {
                'TextToken' {
                    Write-Debug 'Creating Text element'
                    if (-not ([string]::IsNullorEmpty($token.Content))) {
                        Write-Debug "Token content: '$($token.Content)'"
                        $text = (-join @(
                                '"',
                                ($token.Content -replace '"', '`"'),
                                '"',
                                ' | Write-Output'
                        ))
                        Write-Debug "- Block text is [$text]"
                        $element['Block'] = [scriptblock]::Create($text)
                        $elementObject = [PSCustomObject]$element

                        $elementObject.PSTypeNames.Insert(0, 'Stencil.Template.TextElement')
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
                        $element['Options'] = $fm
                        $elementObject = [PSCustomObject]$element

                        $elementObject | Add-Member -MemberType ScriptMethod -Name Block -Value {
                            $this.Options | Write-Output
                        }
                        $elementObject.PSTypeNames.Insert(0, 'Stencil.Template.FrontMatterElement')
                    }
                }
            }

            #! Only produce output if a 'Block' was created
            if ($null -ne $elementObject) {
                $elementObject.PSTypeNames.Insert(1,'Stencil.Template.Element')
                $elementObject | Add-Member -MemberType ScriptMethod -Name 'Invoke' -Value {
                    $this.Block.Invoke()
                }
                $elementObject | Write-Output
            }
            <#
        if you look at the [TT Source](https://github.com/abw/Template2/blob/master/lib/Template/Directive.pm)
        Here you can see that the directives are, themselves templates

        Lets think about what the "end result" should be
        - A PowerShell Object, on the pipeline
          - The metadata associated with the template
            - original text maybe?
            - Block : The "executable" result.  A script block, which when invoked, will produce the desired text
            - The Data table
        - ScriptBlock
          - All of the metadata and anything else we want to "keep" with the result would have to be "in" the
            scriptblock.
        Some examples to walkthrough
        - A TEXT token is the most basic type
          - TEXT tokens will be put back onto the output, so stringbuilder.append or something...
          ```powershell
          $sb = [scriptblock]::Create( { $Template.Content | Write-Output } )
          ```
        - A directive of powershell code would be added to the scriptblock body.
        - A directive where we want to expand a variable , <%= $Greeting %> would go into the scriptblock body
        - a block/end directive: The parser needs a "stream" of tokens so that it can "fold" everything from BLOCK
          to END into one object.
        #>
        }
    }
    end {

        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
