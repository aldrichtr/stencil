
function Resolve-TemplateDirectory {
  <#
  .SYNOPSIS
    Resolve the directory where templates are stored
  #>
  [CmdletBinding()]
  param(
    # The name of the collection to resolve the directory for
    [Parameter(
      Position = 0,
      ValueFromPipeline,
      ValueFromPipelineByPropertyName
    )]
    [string]$Collection
  )
  begin {
    $self = $MyInvocation.MyCommand
    Write-Debug "`n$('-' * 80)`n-- Begin $($self.Name)`n$('-' * 80)"
    $modConfig = Get-ProfileConfiguration -Key 'template'
  }
  process {
    $path = $modConfig.Path.Templates
    if ($path | Test-Path) {
      if ($PSBoundParameters.ContainsKey('Collection')) {
        $possiblePath = (Join-Path $path $Collection)
        if ($possiblePath | Test-Path) {
          $possiblePath
        }
      } else {
        $path
      }
    }
  }
  end {
    Write-Debug "`n$('-' * 80)`n-- End $($self.Name)`n$('-' * 80)"
  }
}
