
using namespace System.Collections
function Get-StencilInfo {
  <#
    .SYNOPSIS
        Get the information for each job defined in the given stencil
    .DESCRIPTION
        `Get-StencilInfo` is used to parse the stencil manifest and return an object representing each job defined
        in the file.
    #>
  [OutputType('Stencil.JobInfo')]
  [CmdletBinding()]
  param(
    # The path to the stencil file to load
    [Parameter(
      ValueFromPipeline,
      ValueFromPipelineByPropertyName
    )]
    [Alias('PSPath')]
    [string[]]$Path,

    # Return a hashtable instead of a `Stencil.JobInfo` object
    [Parameter(
    )]
    [switch]$AsHashtable
  )
  begin {
    Write-Debug "-- Begin $($MyInvocation.MyCommand.Name)"
    $parserOptions = Import-Configuration
    | Select-Object -ExpandProperty Parser
    if ($null -eq $parserOptions) {
      $parserOptions = @{
        AllDocuments     = $true
        UseMergingParser = $true
      }
    }

    $jobNames = [ArrayList]::new() # collect the names so we can "guarantee uniqueness"
  }
  process {
    :file foreach ($p in $Path) {

      # --------------------------------------------------------------------------------
      # #region Import file

      if (-not ($p | Test-Path)) {
        Write-Warning "'$p' is not a valid path"
        continue file
      }
      try {
        $file = Get-Item $p
      } catch {
        Write-Warning "There was an error reading $p`n$_"
        continue file
      }

      try {
        $stencilConfig = Get-Content $p
        | ConvertFrom-Yaml @parserOptions
      } catch {
        throw "Error parsing yaml file $p`n$_"
      }

      if ($stencilConfig.jobs -isnot [hashtable]) {
        throw "in '$p' jobs table is not in the correct format"
      }

      # #endregion Import file
      # --------------------------------------------------------------------------------

      # If there is an `env` table in the stencil file, we will merge it with the env
      # of each job below
      if ($null -ne $stencilConfig.env) {
        $environmentTable = @{
          env = $stencilConfig.env
        }
      } else {
        #TODO (job): Are there certain variables we should add by default?
        $environmentTable = @{
          env = @{}
        }
      }

      :job foreach ($key in $stencilConfig.jobs.Keys) {
        if ($jobNames -contains $key) {
          Write-Warning "Attempt to redefine '$key' in '$p', Skipping"
          continue job
        } else {
          [void]$jobNames.Add($key)

          # --------------------------------------------------------------------------------
          # #region Update job configuration

          $job = $stencilConfig.jobs[$key]

          if ([string]::IsNullorEmpty($job['scope'])) {
            Write-Debug "No scope defined for $key.  Assuming 'global'"
            $job['scope'] = ([JobScope]::global).ToString()
          }

          $paths = @{
            # TODO(job): Need to deprecate SourceDir and CurrentDir
            SourceDir  = $file.Directory.FullName
            CurrentDir = '' # place holder, set at runtime
            Path       = $file.FullName
            # ! new path variables
            src        = $file.Directory.FullName
            cwd        = '' # place holder, set at runtime
          }

          $info = @{
            PSTypeName = 'Stencil.JobInfo'
            Version    = $stencilConfig.Version ?? ''
            id         = $key
          }

          if ($job.Keys -notcontains 'env') {
            # ensure there is an 'env' table to write to
            $job.env = @{}
          }

          #! merge the other information into the job table
          foreach ($table in @($environmentTable, $paths, $info)) {
            $job = $job | Update-Object $table
          }

          # #endregion Update job configuration
          # --------------------------------------------------------------------------------

          if ($AsHashtable) { $job }
          else { [PSCustomObject]$job }
        }
      }
    }
  }
  end {
    Write-Debug "-- End $($MyInvocation.MyCommand.Name)"
  }
}
