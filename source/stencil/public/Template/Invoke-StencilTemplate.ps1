function Invoke-StencilTemplate {
    <#
    .SYNOPSIS
        Execute the directives in the given template to produce the output text
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'AsFile'
    )]
    param(
        # Specifies a path to one or more locations.
        [Parameter(
            ParameterSetName = 'AsFile',
        Position = 0,
        ValueFromPipeline,
        ValueFromPipelineByPropertyName
        )]
        [Alias('PSPath')]
        [string[]]$Path,

        # The template text to execute
        [Parameter(
        )]
        [string]$Template,

        # The data to supply to the template
        [Parameter(
        )]
        [hashtable]$Data
    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    process {
        Write-Debug "`n$('-' * 80)`n-- Process start $($MyInvocation.MyCommand.Name)`n$('-' * 80)"

        Write-Debug "`n$('-' * 80)`n-- Process end $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
