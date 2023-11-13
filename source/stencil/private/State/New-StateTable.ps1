
function New-StateTable {
    <#
    .SYNOPSIS
        Create a structure for maintaining stateTable during stencil invocation
    #>
    [CmdletBinding(
        SupportsShouldProcess
    )]
    param(
    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    process {
        $stateTable = @{
            PSTypeName      = 'Stencil.StateTable'
            Timer           = [System.Diagnostics.Stopwatch]::new()
            StartTime       = Get-Date 0
            EndTime         = Get-Date 0
            SourcePath      = ''
            DestinationPath = ''
            CurrentJob      = ''
            Data            = @{}
            Defaults        = @{}
            Environment     = @{}
            Configuration   = @{}
            Jobs            = [System.Collections.ArrayList]::new()
        }

        try {
            $stateTable.Defaults = Import-Default
            $stateTable.Environment = [System.Environment]::GetEnvironmentVariables()
            $stateTable.Configuration = Import-Configuration
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
        $stateObject = [PSCustomObject]$stateTable
        #-------------------------------------------------------------------------------
        #region Timer functions

        $stateObject | Add-Member -MemberType ScriptMethod -Name Start -Value {
            $this.StartTime = Get-Date
            $this.EndTime = Get-Date 0
            if ($this.Timer.IsRunning) {
                $this.Timer.Restart()
            } else {
                $this.Timer.Start()
            }
        }
        $stateObject | Add-Member -MemberType ScriptMethod -Name Stop -Value {
            $this.EndTime = Get-Date
            if ($this.Timer.IsRunning) {
                $this.Timer.Stop()
            } else {
                $this.Timer.Start()
            }
        }

        #endregion Timer functions
        #-------------------------------------------------------------------------------

        #-------------------------------------------------------------------------------
        #region Job functions


        #endregion Job functions
        #-------------------------------------------------------------------------------

        if ($PSCmdlet.ShouldProcess('State', 'Create new stateTable')) {
            $stateObject | Write-Output
        }
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
