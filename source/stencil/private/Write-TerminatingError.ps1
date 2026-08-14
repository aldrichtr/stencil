
using namespace System.Management.Automation

function Write-TerminatingError {
  <#
  .SYNOPSIS
    Throw a terminating error
  #>
  [CmdletBinding()]
  param(
    # The Error
    [Parameter(
      ValueFromPipeline
    )]
    [Object]$ErrorRecord,

    # The message to add to the error report
    [Parameter(
    )]
    [string]$Message

  )
  process {
    if (-not ($PSBoundParameters.ContainsKey('Message'))) {
      $Message = 'There was an error'
    }

    $exceptionText = ( @($Message, $ErrorRecord.ToString()) -join "`n")
    $newException = [Exception]::new($exceptionText)
    $eRecord = [ErrorRecord]::new(
      $newException,
      $Object.FullyQualifiedErrorId,
      $Object.CategoryInfo.Category,
      $null
    )
    $PSCmdlet.ThrowTerminatingError( $eRecord )
  }
}
