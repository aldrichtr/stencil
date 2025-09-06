
function Invoke-Stencil {
  [CmdletBinding(
    DefaultParameterSetName = 'Default'
  )]
  param(
    # An alternate path to the root of the stencil folders
    [Parameter(
      ParameterSetName = 'Default',
      Position = 0
    )]
    [string]$Path,

    # The stencil.JobInfo to run
    [Parameter(
      ParameterSetName = 'FromJob',
      Position = 1,
      ValueFromPipeline,
      ValueFromPipelineByPropertyName
    )]
    [PSTypeNameAttribute('Stencil.JobInfo')][Object[]]$Job,

    # One or more jobs to invoke
    [Parameter(
      ParameterSetName = 'Default',
      ValueFromPipeline,
      ValueFromPipelineByPropertyName
    )]
    [string[]]$Id,

    # Write the current configuration to the console
    [Parameter(
      ParameterSetName = 'Config'
    )]
    [switch]$ShowConfig
  )
  begin {
    Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"

    Write-Debug '  Loading configuration'
    $state = Get-StateTable
    $state.Start()
    if ($ShowConfig) {
      $state | ConvertTo-Yaml | Write-Output
      break
    }
    $config = $state.Configuration
    <#------------------------------------------------------------------
        1.  Load the operations registry
        ------------------------------------------------------------------#>

   Initialize-StencilOperationRegistry

    <#------------------------------------------------------------------
        2.  Determine all of the paths that stencils should be loaded from

          a. The path(s) given as a parameter
          b. The $StencilPath variable
              TODO: should this be an environment variable?
          c. The default location ($config.Default.Directory)
          d. The current directory
        ------------------------------------------------------------------#>
    if (-not($PSBoundParameters.ContainsKey('Path'))) {
      $jobPath = (Join-Path $config.Default.Path.Root $config.Default.Path.Jobs)
      if ($null -ne $StencilPath) {
        Write-Verbose "`$StencilPath is set to $StencilPath"
        $Path = ($StencilPath -split ';')
      } elseif (Test-Path $jobPath) {
        $Path = $jobPath
      } else {
        $Path = (Get-Location).Path
      }
    }

    Write-Verbose "  Looking for stencils in $Path"
    Get-Stencil -Path $Path -All | ForEach-Object { [void]$state.Jobs.Add($_) }
    Write-Verbose "  Loaded $($state.Jobs.Count) jobs"
  }
  process {
    if (-not ($PSBoundParameters.ContainsKey('Job'))) {
      Write-Debug 'No Job given'
      if (-not ($PSBoundParameters.ContainsKey('Id'))) {
        throw "No Job and no id given.  Can't continue"
      } else {
        Write-Debug "Looking up id $Id"
        $possibleJob = $state.Jobs | Where-Object -Property id -Like $Id
        if ($null -ne $possibleJob) {
          try {
            Write-Debug 'Running this job'
            $possibleJob | Invoke-StencilJob
          } catch {
            $PSCmdlet.ThrowTerminatingError($_)
          }
        } else {
          throw "No job found with id '$Id'"
        }
      }
    } else {
      Write-Debug 'A Job was given'
      try {
        Write-Debug 'Running this job'
        $Job | Invoke-StencilJob
      } catch {
        $PSCmdlet.ThrowTerminatingError($_)
      }
    }
  }
  end {
    #TODO: Need a proper shutdown and report process here
    $state.Stop()
    $script:__StateTable = $null
    Write-Debug "-- End $($MyInvocation.MyCommand.Name)"
  }
}
