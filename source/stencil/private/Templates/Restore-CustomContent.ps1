
function Restore-CustomContent {
  <#
  .SYNOPSIS
    Add the Custom Content to the output
  #>
  [CmdletBinding()]
  param(
    # The output of the template after it has been extracted
    [Parameter(
    )]
    [string[]]$Output


  )
  begin {
    $self = $MyInvocation.MyCommand
    Write-Debug "`n$('-' * 80)`n-- Begin $($self.Name)`n$('-' * 80)"
  }
  process {

  }
  end {
    Write-Debug "`n$('-' * 80)`n-- End $($self.Name)`n$('-' * 80)"
  }
}