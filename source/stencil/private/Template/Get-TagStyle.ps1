function Get-TagStyle {
    <#
    .SYNOPSIS
        Get the style options for the StartTag, EndTag and Escape characters from the configuration or the default
    .DESCRIPTION
        The config file should contain two keys under Template; `TagStyle` and `TagStyleMap`
        The `TagStyleMap` sets the characters to use for the given TagStyle, and TagStyle sets which one to use.
    #>
    [CmdletBinding()]
    param(
        # The tag style to use
        [Parameter(
        )]
        [string]$TagStyle
    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
        $defaultStartTag = '<%'
        $defaultEndTag = '%>'
        $defaultEscape = '%'
    }
    process {
        $config = Import-Configuration
        | Select-Object -ExpandProperty Template

        if ($null -eq $config) {
            $config = @{
                TagStyle    = 'default'

                TagStyleMap = @{
                    default = @($defaultStartTag, $defaultEndTag, $defaultEscape)
                }
            }
        }

        if ([string]::IsNullorEmpty($TagStyle)) {
            if (-not ([string]::IsNullOrEmpty($config.TagStyle))) {
                $TagStyle = $config.TagStyle
            }
        }

        if ($config.ContainsKey('TagStyleMap')) {

            if ($config.TagStyleMap.ContainsKey($config.TagStyle)) {
                $startTag, $endTag, $escapeChar = $config.TagStyleMap[$config.TagStyle]
            }
        }

        if ($null -eq $startTag) { $startTag = $defaultStartTag }
        if ($null -eq $endTag) { $endTag = $defaultEndTag }
        if ($null -eq $escapeChar) { $escapeChar = $defaultEscape }

        Write-Output @($startTag, $endTag, $escapeChar)
    } end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
