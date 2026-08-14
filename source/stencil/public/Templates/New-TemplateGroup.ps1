
using namespace System.Collections
using namespace Antlr4.StringTemplate


function New-TemplateGroup {
  <#
  .SYNOPSIS
    Create a [TemplateGroup] from either a StringTemplate Group file (.stg) or a Directory of Template files (.st)
  .OUTPUT
    [Antlr4.StringTemplate.TemplateGroup]
  #>
  [CmdletBinding(
    DefaultParameterSetName = 'asPath'
  )]
  param(
    # Specifies a path to a template or a directory of templates
    [Parameter(
      ParameterSetName = 'asPath',
      Position = 0,
      ValueFromPipelineByPropertyName
    )]
    [Alias('PSPath')]
    [string]$Path,

    # Pass in a Block of text to be evaluated
    [Parameter(
      ParameterSetName = 'asText',
      Position = 0,
      ValueFromPipelineByPropertyName
    )]
    [string[]]$Definition
  )
  begin {
    $self = $MyInvocation.MyCommand
    Write-Debug "`n$('-' * 80)`n-- Begin $($self.Name)`n$('-' * 80)"
    $collect = [ArrayList]::new()
  }
  process {
    Write-Debug "Received parameters $($PSBoundParameters.Keys -join ', ')"
    if ($PSBoundParameters.ContainsKey('Definition')) {
      Write-Debug 'Received text for Definition'
      [void]$collect.Add($Definition)

    } elseif ($PSBoundParameters.ContainsKey('Path')) {
      Write-Debug "Received '$Path' to create new TemplateGroup"
      if ($Path | Test-Path) {
        try {
          $PathInfo = $Path | Resolve-Path | Get-Item
          Write-Debug "- Type is $($PathInfo.GetType().FullName)"
        } catch {
          throw "There was an error reading Path $Path`n$_"
        }

        if ($PathInfo.PSISContainer) {
          Write-Debug '- It is a directory'
          try {
            $group = [TemplateGroupDirectory]::new($PathInfo.FullName)
          } catch {
            throw "There was an error loading templates in $Path`n$_"
          }
        } else {
          Write-Debug '- It is a file'
          try {
            $group = [TemplateGroupFile]::new($PathInfo.FullName)
          } catch {
            throw "There was an error importing group file $Path`n$_"
          }
        }
        $group
      }
    } else {
      $PSCmdlet.WriteWarning("$Path is not a valid path. Skipping")
    }
  }
  end {
    if ($collect.Count -gt 0) {
      Write-Debug 'Received Definition. Creating template'
      try {
        $group = [TemplateGroupString]::new($collect -join "`n")
      } catch {
        "There was an error reading definition`n$_"
      }
      $group
    }
    Write-Debug "`n$('-' * 80)`n-- End $($self.Name)`n$('-' * 80)"
  }
}
