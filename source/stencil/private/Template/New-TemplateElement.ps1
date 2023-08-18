
function New-TemplateElement {
    <#
    .SYNOPSIS
        Create a new 'Stencil.TemplateElement' object
    #>
    [OutputType('Stitch.TemplateElement')]
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'low'
    )]
    param(

        # The type of Template element to create
        [Parameter(
        )]
        [string]$Type,

        # The content text of the element
        [Parameter(
            ValueFromPipeline
        )]
        [string]$Content,

        # The starting position of the template element in the original content
        [Parameter(
        )]
        [int]$Start,

        # The length of the element
        [Parameter(
        )]
        [int]$Length,

        # Whether to remove leading whitespace from the result
        [Parameter(
        )]
        [switch]$RemoveLeadingWhitespace,

        # Whether to remove trailing line ending from the result
        [Parameter(
        )]
        [switch]$RemoveTrailingLineEnding,

        # The name of the element
        [Parameter(
        )]
        [string]$Name,

        # Metadata associated with the template element
        [Parameter(
        )]
        [hashtable]$Data
    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)"
        $Options = @{
            Option = 'Constant'
            Name = 'DEFAULT_TYPE'
            Value = 'Text'
            Description = "The default TemplateElement Type"
        }

        New-Variable @Options
    }
    process {

        if ($PSCmdlet.ShouldProcess($Name, 'Create new Stitch.TemplateElement')) {
            $textInfo = (Get-Culture).TextInfo
            $typeName = $textInfo.ToTitleCase($Type)

            [PSCustomObject]@{
                PSTypeName     = "Stencil.TemplateElement.$typeName"
                #! Default type is Content
                Type           = $Type ?? $DEFAULT_TYPE
                Name           = $Name ?? ''
                Content        = $Content ?? ''
                Data           = $Data ?? @{}
                Start          = $Start ?? 0
                Length         = $Length ?? 0
                RemoveLeading  = $RemoveLeadingWhitespace ? $true : $false
                RemoveTrailing = $RemoveTrailingLineEnding ? $true : $false
            }
            | Write-Output
        }
    }
    end {
        Write-Debug "-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
