
function Find-CustomContent {
  <#
  .SYNOPSIS
    Isolate the content that is between the markers in a file.
  #>
  [CmdletBinding()]
  param(
    # The text to find custom content in
    [Parameter(
      ValueFromPipeline
    )]
    [string[]]$InputObject
  )
  begin {
    $self = $MyInvocation.MyCommand
    Write-Debug "`n$('-' * 80)`n-- Begin $($self.Name)`n$('-' * 80)"
    $config = Import-Configuration
    $collect = [System.Collections.ArrayList]::new()
    $shouldOutput = $false
  }
  process {
    $lines = $InputObject.Split("`n")
    $collect.AddRange($lines)
  }
  end {
    Write-Debug "Looking for $($config.MagicComment) in content"
    $lineNumber = 0
    foreach ($line in $collect) {
      Write-Debug "Processing ${lineNumber}: $line"
      $null = $line -match [regex]::Escape($config.MagicComment)
      if ($Matches.Count -gt 0) {
        Write-Debug "- Found marker"
        if ($shouldOutput) {
          # NOTE: We are already inside the custom content, so we stop here
          $shouldOutput = $false
          Write-Debug "  - Stop processing"
        } else {
          Write-Debug "  - Start processing"
          $shouldOutput = $true
        }
      }

      if ($shouldOutput) { $line }
      $lineNumber++
    }
    Write-Debug "`n$('-' * 80)`n-- End $($self.Name)`n$('-' * 80)"
  }
}