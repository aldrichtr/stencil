
using namespace Antlr4.StringTemplate
using namespace System.Collections

function Expand-Template {
  <#
  .SYNOPSIS
    Render the template
  #>
  [CmdletBinding(
    DefaultParameterSetName = 'AsPath'
  )]
  param(
    # Specifies a path to one or more locations.
    [Parameter(
      ParameterSetName = 'AsPath',
      Position = 1,
      ValueFromPipeline,
      ValueFromPipelineByPropertyName
    )]
    [Alias('PSPath')]
    [string]$Path,

    # The template definition
    [Parameter(
      ParameterSetName = 'AsDef',
      ValueFromPipelineByPropertyName
    )]
    [string[]]$Definition,

    # The name of the template within the group to render
    [Parameter(
      Position = 0,
      ValueFromPipelineByPropertyName
    )]
    [string]$Name,

    # The Type of Template in the Definition.  Possible options are 'Group' or 'Single'
    [Parameter(
      ValueFromPipelineByPropertyName
    )]
    [ValidateSet('Group', 'Single')]
    [string]$Type,

    # Parameters to pass into the template
    [Parameter()]
    [hashtable]$Parameters
  )
  begin {
    $self = $MyInvocation.MyCommand
    Write-Debug "`n$('-' * 80)`n-- Begin $($self.Name)`n$('-' * 80)"
    $collect = [ArrayList]::new()
  }
  process {
    if ($PSCmdlet.ParameterSetName -eq 'AsDef') {
      foreach ($line in $Definition) { $null = $collect.Add($line) }
    }
  }
  end {
    # SECTION Import the template group
    try {
      if ($collect.Count -gt 0) {
        Write-Debug 'Creating template object from content'
        $body = $collect -join "`n"
        $group = New-TemplateGroup -Definition $body
      } elseif ($PSBoundParameters.ContainsKey('Path')) {
        Write-Debug "Creating template object from file '$Path'"
        $group = New-TemplateGroup -Path $Path
      } else {
        throw 'No content or path was received'
      }
    } catch {
      $err = $_ # The original error
      $message = 'Could not create template'
      $exceptionText = ( @($message, $err.ToString()) -join "`n")
      $newException = [Exception]::new($exceptionText)
      $eRecord = [System.Management.Automation.ErrorRecord]::new(
        $newException,
        $err.FullyQualifiedErrorId,
        $err.CategoryInfo.Category,
        $group ?? $null
      )
      $PSCmdlet.ThrowTerminatingError( $eRecord )
    }
    # !SECTION Import the template group

    # SECTION Get template from group
    if (-not ($PSBoundParameters.ContainsKey('Name'))) {
      try {
        Write-Debug "No template name given, attempting to find $Name in template group"
        $Name = $Group.GetTemplateNames() |
          Select-Object -First 1
        Write-Debug "- Found '$Name'"
      } catch {
        $err = $_ # The original error
        $message = 'Could not determine which template in the input to Expand.'
        $exceptionText = ( @($message, $err.ToString()) -join "`n")
        $newException = [Exception]::new($exceptionText)
        $eRecord = [System.Management.Automation.ErrorRecord]::new(
          $newException,
          $err.FullyQualifiedErrorId,
          $err.CategoryInfo.Category,
          $group
        )
        $PSCmdlet.ThrowTerminatingError( $eRecord )
      }
    }

    if ($null -eq $Name) {
      throw "No Name was given and could not find Name in template"
    }

    $template = $group.GetInstanceOf($Name)
    if ($null -eq $template) { throw "Did not find $Name in template" }
    # !SECTION Get template from group

    # TODO: This should be the "plumbing" function, but need a function that gets the data from the data directory
    #       For this template, and that "transfers" the content between magic-comment markers
    if ($PSBoundParameters.ContainsKey('Parameters')) {
      Write-Debug 'Importing Parameters'
      $Parameters.GetEnumerator() |
        ForEach-Object { $null = $template.Add($_.Key, $_.Value) }
    }

    Write-Debug "Template :`n$($template | Get-Member | Out-String)"
    if ($VerbosePreference -eq 'Continue') {
      $template.Verbose = $true
    }

    Write-Debug 'Rendering template'
    $template.Render()

    Write-Debug "`n$('-' * 80)`n-- End $($self.Name)`n$('-' * 80)"
  }
}
