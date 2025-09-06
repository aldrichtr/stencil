
function Reset-StencilOperationRegistry {
  <#
  .SYNOPSIS
    Reset the Registry back to empty
  #>
  [CmdletBinding()]
  param(
  )
  begin {
    Write-Debug "-- Begin $($MyInvocation.MyCommand.Name)"
  }
  process {
   New-StencilOperationRegistry -Force
  }
  end {
    Write-Debug "-- End $($MyInvocation.MyCommand.Name)"
  }
}
