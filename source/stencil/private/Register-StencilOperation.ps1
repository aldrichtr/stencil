
function Register-StencilOperation {
    <#
    .SYNOPSIS
        Add a DSL word to the Stencil workflow
    .DESCRIPTION
        Register a DSL word (-Name) that maps to a Command or Scriptblock for use in stencil workflows
    .EXAMPLE
        Register-StencilOperation -Name copy -Command Copy-Item -Description "Copy items from Path to Destination"
    .EXAMPLE
        Register-StencilOperation -Name 'read' -ScriptBlock { param($options)
           Set-Variable -Name $options.Name -Value (Read-Host $options.Prompt)
        } -Description "Read a value from the user"
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Command'
    )]
    param(
        # Name of the Operation for use in stencils
        [Parameter(
            Position = 1,
            Mandatory
        )]
        [string]$Name,

        # The Command that the operation calls
        [Parameter(
            Position = 2,
            ParameterSetName = 'Command'
        )]
        [string]$Command,

        # The scriptblock the operation calls
        [Parameter(
            Position = 2,
            ParameterSetName = 'ScriptBlock'
        )]
        [scriptblock]$ScriptBlock,

        # An optional description
        [Parameter(
            Position = 3
        )]
        [string]$Description,

        # Optionally return the registered operation
        [Parameter(
        )]
        [switch]$Passthru,

        # Optionally overwrite an existing Operation
        [Parameter(
        )]
        [switch]$Force

    )
    begin {
        Write-Debug "-- Begin $($MyInvocation.MyCommand.Name)"
        $registry = Get-StencilOperationRegistry
    }
    process {
        if ((-not($registry.ContainsKey($Name))) -or $Force) {
            Write-Verbose "Registering the operation '$Name'"
            if ($PSBoundParameters.ContainsKey('Command')) {
                Write-Debug "  operation is a wrapper for '$Command'.  Generating scriptblock"
                $cmd = "param(`$params) $Command @params"
                $ScriptBlock = [scriptblock]::create($cmd)
            } else {
                Write-Debug "  operation is a scriptblock"
            }
            $registry[$Name] = @{
                Command     =  $ScriptBlock
                Description = $Description ?? ''
            }
        } else {
            $options = @{
                Message           = "Could not register '$Name'"
                Category          = 'ResourceExists'
                RecommendedAction = "Remove duplicate ids or Use '-Force' to overwrite"
            }
            Write-Error @options
        }
    }
    end {
        if ($Passthru) {
            $registry[$Name]
        }
        Write-Debug "-- End $($MyInvocation.MyCommand.Name)"
    }
}
