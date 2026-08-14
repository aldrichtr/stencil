
using namespace Scriban

function New-TemplateContext {
  <#
  .SYNOPSIS
    Create a new TemplateContext object
  #>
  [CmdletBinding(
    SupportsShouldProcess,
    ConfirmImpact="Low"
  )]
  param(
  )
  begin {
    $self = $MyInvocation.MyCommand
    Write-Debug "`n$('-' * 80)`n-- Begin $($self.Name)`n$('-' * 80)"
  }
  process {
    try {
      if ($PSCmdlet.ShouldProcess("TemplateContext", "Create")) {
        [TemplateContext]::new()
      }
    }
    catch {
      Write-TerminatingError $_ -Message "There was an error creating the context"
    }
  }
  end {
    Write-Debug "`n$('-' * 80)`n-- End $($self.Name)`n$('-' * 80)"
  }
}
