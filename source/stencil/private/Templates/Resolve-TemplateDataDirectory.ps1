using namespace System.IO


function Resolve-TemplateDataDirectory {
  <#
  .SYNOPSIS
    Resolve the path to the root of the Data directory used for adding parameters to templates
  #>
  [CmdletBinding()]
  param(
    # Specifies a path to one or more locations.
    [Parameter(
    Position = 0,
    ValueFromPipeline,
    ValueFromPipelineByPropertyName
    )]
    [Alias('PSPath')]
    [string[]]$Path
  )
  begin {
    $self = $MyInvocation.MyCommand
    Write-Debug "`n$('-' * 80)`n-- Begin $($self.Name)`n$('-' * 80)"
  }
  process {
    Get-ProfileConfiguration -key 'template' |
      Select-Object -ExpandProperty Path |
        Select-Object -ExpandProperty Data


  }
  end {
    Write-Debug "`n$('-' * 80)`n-- End $($self.Name)`n$('-' * 80)"
  }
}
