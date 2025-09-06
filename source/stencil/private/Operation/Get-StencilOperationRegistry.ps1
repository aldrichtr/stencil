
function Get-StencilOperationRegistry {
  <#
  .SYNOPSIS
    Return the registry creating it first if it does not exist
  .DESCRIPTION
    The OperationRegistry is a table of all the Stencil Operations
  #>
  [CmdletBinding()]
  param(
  )
  begin {
    Write-Debug "-- Begin $($MyInvocation.MyCommand.Name)"
  }
  process {
    if (-not(Test-StencilOperationRegistry)) {
      Write-Debug '  script registry not set.  Adding module variable StencilOperationRegistry'
      $script:StencilOperationRegistry = @{}
    }
    return $script:StencilOperationRegistry
  }
  end {
    Write-Debug "-- End $($MyInvocation.MyCommand.Name)"
  }
}
