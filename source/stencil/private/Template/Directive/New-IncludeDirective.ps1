
using namespace System
using namespace System.Collections
function New-IncludeDirective {
    <#
    .SYNOPSIS
        Create a directive object that includes the content of the given file
    #>
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'low'
    )]
    param(
        # The content of the template directive
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [string]$Content
    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    process {
        Write-Debug "`n$('-' * 80)`n-- Process start $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
        if ($PSCmdlet.ShouldProcess('Directive', 'Create Include Directive')) {
            $result = $Content | Convert-DirectiveParameter

            if ($null -ne $result.Parameters) {
                Write-Debug "Received $($result.Parameters.Count)"
            }
            $remainingContent = $result.Content

            $parts = $remainingContent -split ' '
            <#
             At this point, we should have removed any parameters, and the directive name
             if any were present.  We should only have a path to work with now
            #>
            if ($parts.Count -gt 1) {
                Write-Debug 'There is still data here :'
                throw "Extra data in Include directive $($parts -join ', '))"
            } else {
                $possiblePath = $PSCmdlet.InvokeCommand.ExpandString($parts[0])
                $possiblePath = $possiblePath -replace '"', '' -replace "'", ''
                Write-Debug "$($parts[0]) is the last item.  Checking for file $possiblePath"
                #TODO: Need to be able to pass in the starting path ?
                if (Test-Path $possiblePath) {
                    Write-Verbose " Found $possiblePath"
                    $path = $possiblePath
                } elseif (Test-Path (Join-Path (Get-Location) $possiblePath)) {
                    $path = (Join-Path (Get-Location) $possiblePath)
                } else {
                    throw "Could not find include file $possiblePath"
                }

                Write-Verbose "Loading included file $path"
                $directive = ( @(
                        '@"',
                        (Get-Content $path),
                        '"@',
                        [System.Environment]::NewLine
                    ) -join [System.Environment]::NewLine
                )
            }

        }
        Write-Debug "`n$('-' * 80)`n-- Process end $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    end {
        $directive
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
