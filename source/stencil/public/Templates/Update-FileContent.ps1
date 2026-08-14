
function Update-FileContent {
  <#
  .SYNOPSIS
    Assuming that this file was created with a template, update the template output, preserving the CustomContent if
    there is any
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
    [string[]]$Path,

    # The output of the template
    [Parameter()]
    [string[]]$InputObject,

    # Do not write the content back to the file, good for testing final output
    [Parameter(
    )]
    [switch]$NoWrite
  )
  begin {
    $self = $MyInvocation.MyCommand
    Write-Debug "`n$('-' * 80)`n-- Begin $($self.Name)`n$('-' * 80)"
    $collect = [System.Collections.ArrayList]::new()
  }
  process {
    $InputObject = ($InputObject -join "`n")
    if ($Path | Test-Path) {
      # First mark the place in the template output to be replaced
      $marker = $InputObject | Find-CustomContent
      # Next, mark the content in the existing file to be excluded
      $originalContent = Get-Content $Path
      $customContent = Get-Content $Path | Find-CustomContent

      if ([string]::IsNullorEmpty($marker) -or [string]::IsNullorEmpty($customContent)) {
        throw 'Custom content markers must exist in both output and file'
      }
      # NOTE: ok, this one is weird... if you have a $_ in the custom content, it gets
      # replaced with the full text.  So first we "disrupt" the $_ to get the content
      # into the output, then put the _ back
      $customContent = $customContent -replace '\$_', "`$@@underbar@@"

      $finalContent = ( $InputObject -replace $marker, $customContent)
      $finalContent = $finalContent -replace '@@underbar@@', '_'

      if ($NoWrite) {
        $finalContent -split "`n"
      } else {
        try {
          $finalContent | Set-Content $Path
        } catch {
          throw "There was an error writing content to the file`n$_"
        }
      }
    }
  }
  end {
    Write-Debug "`n$('-' * 80)`n-- End $($self.Name)`n$('-' * 80)"
  }
}