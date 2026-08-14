
using namespace System.Collections

function Import-Template {
  <#
  .SYNOPSIS
    Parse a template into a Scriban.Template object
  .EXAMPLE
    PS> $foo = Get-Content foo.pst1 | Import-Template
  .EXAMPLE
    PS> $foo = Get-Item foo.pst1 | Import-Template
  .EXAMPLE
    PS> $foo = Import-Template -Path foo.pst1
  #>
  [CmdletBinding(
    DefaultParameterSetName = 'AsText'
  )]
  param(
    # Specifies a path to one or more locations.
    [Parameter(
      ParameterSetName = 'AsPath',
      Position = 0,
      ValueFromPipelineByPropertyName
    )]
    [Alias('PSPath')]
    [string[]]$Path,

    # Template content
    [Parameter(
      ParameterSetName = 'AsText',
      Position = 0,
      ValueFromPipeline,
      ValueFromPipelineByPropertyName
    )]
    [string[]]$Content
  )
  begin {
    $self = $MyInvocation.MyCommand
    Write-Debug "`n$('-' * 80)`n-- Begin $($self.Name)`n$('-' * 80)"
    $collect = [ArrayList]::new()
  }
  process {
    switch ($PSCmdlet.ParameterSetName) {
      'AsText' {
        $null = $collect.Add($Content)
      }
      'AsPath' {
        return Convert-TemplateSource -Path $Path
      }
    }
  }
  end {
    if (($null -eq $collect) -or ($collect.Count -eq 0)) {
      Convert-TemplateSource -Content ($collect -join "`n")
    }
    Write-Debug "`n$('-' * 80)`n-- End $($self.Name)`n$('-' * 80)"
  }
}
