
function Get-StencilOperationHelp {
  <#
  .SYNOPSIS
    Retrieve the Help commentary for the given operation
  #>
  [CmdletBinding()]
  param(
    # The name of the operation to get help for
    [Parameter(
      Position = 0,
      ValueFromPipeline,
      ValueFromPipelineByPropertyName
    )]
    [string]$Name
  )
  begin {
    $self = $MyInvocation.MyCommand
    Write-Debug "`n$('-' * 80)`n-- Begin $($self.Name)`n$('-' * 80)"
  }
  process {
    if (-not ($PSBoundParameters.ContainsKey('Name'))) {
      $Name = (Get-StencilOperationRegistry).Keys
    }

  }
  end {
    Write-Debug "`n$('-' * 80)`n-- End $($self.Name)`n$('-' * 80)"
  }
}
