
function New-StencilOperationRegistry {
  <#
  .SYNOPSIS
    Create a Stencil Operation Registry singleton
  #>
  [CmdletBinding()]
  param(
    # Overwrite the registry if it exists
    [Parameter(
    )]
    [switch]$Force
  )
  begin {
    $self = $MyInvocation.MyCommand
    Write-Debug "`n$('-' * 80)`n-- Begin $($self.Name)`n$('-' * 80)"
  }
  process {
    if (Test-StencilOperationRegistry) {
      if (-not $Force) {
        throw 'Registry already exists, use -Force to override'
      }
    }
    $script:StencilOperationRegistry = @{}
  }
  end {
    Write-Debug "`n$('-' * 80)`n-- End $($self.Name)`n$('-' * 80)"
  }
}
