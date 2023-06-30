
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
        if ($PSCmdlet.ShouldProcess("Directive", "Create Include Directive")) {
            $splitOptions = [StringSplitOptions]::RemoveEmptyEntries + [StringSplitOptions]::TrimEntries
            $parts = [ArrayList]::new($Content.Split(' ', $splitOptions))
            #TODO: Extracting the parameters needs to be pulled up into it's own function
            # I could do something like send the content to `Format-ContentParameters` and then
            # return a hash with a 'Parameters' key and a 'Content' key which would be the remaining
            $parameters = @{}
            $toBeRemoved = @()

            foreach ($part in $parts) {
                if ($part.StartsWith('-')) {
                    Write-Debug "$part is a parameter"
                    $partIndex = $parts.IndexOf($part)
                    $nextIndex = $partIndex + 1
                    $nextValue = $parts[$nextIndex]

                    $parameterName = $part.Remove(0,1)
                    if ($nextIndex -le $parts.Count) {
                        # The next item in the list is not another parameter
                        if ($nextValue.StartsWith('-')) {
                            $parameters.Add($parameterName, $true)
                        } else {
                            $parameters.Add($parameterName, $nextValue)
                            $toBeRemoved += $nextValue
                        }
                    } else {
                        $parameters.Add($parameterName, $true)
                    }
                    $toBeRemoved += $part
                }
            }

            foreach ($word in $toBeRemoved) { $null = $parts.Remove($word) }
            Write-Debug "Parameters are : $($parameters | ConvertTo-Json)"
            if ($parts[0] -like 'include') {
                Write-Debug "We did receive a $($parts[0]) directive"
                $null = $parts.RemoveAt(0)
                Write-Debug "Removed.  The next part is $($parts[0])"
            } else {
                Write-Debug "Must have been using the '+' key"
                Write-Debug "The next part is $($parts[0])"
            }

            <#
             At this point, we should have removed any parameters, and the directive name
             if any where present.  We should only have a path to work with now
            #>
            if ($parts.Count -gt 1) {
                Write-Debug "There is still data here :"
                throw "Extra data in Include directive $($parts -join ', '))"
            } else {
                $possiblePath = $PSCmdlet.InvokeCommand.ExpandString($parts[0])
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
                $directive = "Write-Output @`"`n$(Get-Content $path)`n`"@"
            }

        }
        Write-Debug "`n$('-' * 80)`n-- Process end $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    end {
        $directive
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
