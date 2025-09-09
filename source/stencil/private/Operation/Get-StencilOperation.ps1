
function Get-StencilOperation {
  [CmdletBinding()]
  param(
    # The operation to lookup
    [Parameter(
      Position = 0,
      ValueFromPipeline,
      ValueFromPipelineByPropertyName
    )]
    [string]$Name
  )
  begin {
    Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
  }
  process {
    (Get-StencilOperationRegistry).GetEnumerator() |
      ForEach-Object {
        if ((-not ($PSBoundParameters.ContainsKey('Name'))) -or
          ($Name -like $_.Key)) {
          $_.Value
        }
      }
  }
  end {
    Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
  }
}
