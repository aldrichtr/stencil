
function Initialize-StencilOperationRegistry {
  <#
  .SYNOPSIS
    Create the registry and register all known operations
  #>
  [CmdletBinding()]
  param(
  )
  begin {
    $self = $MyInvocation.MyCommand
    Write-Debug "`n$('-' * 80)`n-- Begin $($self.Name)`n$('-' * 80)"
    $modConfig = Import-Configuration
  }
  process {
    $paths = @(
      $modConfig.Registry.Path, # These are the operations shipped with the module
      $modConfig.Default.Path.Operations # These are the user's additional operations
    )

    Reset-StencilOperationRegistry
    foreach ($path in $paths) {
      $options = @{
        Path = $path
        Filter = '*.operation.ps1'
        Recurse = $true
      }
      Get-ChildItem @options |
      Foreach-Object {
           Write-Debug "Importing operation $($_.BaseName)"
           # TODO: Yeah, this is dangerous if someone else writes the operation....
           . $_.FullName
        }
    }

  }
  end {
    Write-Debug "`n$('-' * 80)`n-- End $($self.Name)`n$('-' * 80)"
  }
}
