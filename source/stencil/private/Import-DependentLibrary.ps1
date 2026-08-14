
using namespace System.IO

function Import-DependentLibrary {
  <#
  .SYNOPSIS
    Load the DLL from the Module directory.
  .DESCRIPTION
    Dotnet downloads packages to a directory like `<library-name>/<library-version>`.
    Within that directory is a `lib/` directory with assemblies organized by which dotnet
    version they target ('8.0', '10.0', etc).

    So the path will be something like:
    `bin/markdig/1.1.2/lib/net10.0/markdig.dll`
  #>
  [CmdletBinding()]
  param(
    # The name of the library to load
    [Parameter(
      Mandatory
    )]
    [string]$Name,

    # The DotNet version of the dll to load
    [Parameter(
    )]
    [ValidateSet('8.0', '9.0', '10.0', '462', 'standard2.0', 'standard2.1')]
    [string]$DotNetVersion,

    # The library version to load
    [Parameter(
    )]
    [string]$LibraryVersion
  )
  begin {
    $self = $MyInvocation.MyCommand
    Write-Debug "`n$('-' * 80)`n-- Begin $($self.Name)`n$('-' * 80)"
    # TODO Set the DLL directory in the startup of the module

    $moduleDir = Split-Path $self.Module.Path # the directory the module (psm1) is loaded from
    $base = 'bin'                             # the directory where libraries are added
    $baseDir = (Join-Path $moduleDir $base)   # create the fully-qualified path


    $prefix = 'net'
  }
  process {


    # --------------------------------------------------------------------------------------------------
    # SECTION Path validation
    #
    # NOTE: We are being overly cautious here, but we test the generated path at each level.  The
    #       whole thing is wrapped in a try and at each step we throw if the path is not valid
    try {
      $packagePath = (Join-Path $baseDir $Name)
      if (-not ($packagePath | Test-Path -IsValid)) { throw "No package '$Name' found in module" }
      $libPath = (Join-Path -Path $packagePath -ChildPath $LibraryVersion 'lib')
      if (-not ($libPath | Test-Path -IsValid)) { throw "Library path '$libPath' not found in module" }
      $dllPath = (Join-Path $libPath "$prefix$DotNetVersion" "$Name.dll")
      if (-not ($dllPath | Test-Path -IsValid)) { throw "Assembly '$Name.dll' not found in module" }
    } catch {
      $err = $_ # The original error
      $message = 'Could not load library'
      $exceptionText = ( @($message, $err.ToString()) -join "`n")
      $newException = [Exception]::new($exceptionText)
      $eRecord = [System.Management.Automation.ErrorRecord]::new(
        $newException,
        $err.FullyQualifiedErrorId,
        $err.CategoryInfo.Category,
        $dllpath
        )
        $PSCmdlet.ThrowTerminatingError( $eRecord )
      }
      # !SECTION
      # --------------------------------------------------------------------------------------------------

    Write-Debug "Loading library from $dllpath"
    #NOTE: We can be sure that the path is valid, now we try to load it
    try {
      $dllData = [File]::ReadAllBytes($dllpath)
      $script:mdAssembly = [System.Reflection.Assembly]::Load($dllData)
    } catch {
      $err = $_ # The original error
      $message = 'Could not load Markdig library'
      $exceptionText = ( @($message, $err.ToString()) -join "`n")
      $newException = [Exception]::new($exceptionText)
      $eRecord = [System.Management.Automation.ErrorRecord]::new(
        $newException,
        $err.FullyQualifiedErrorId,
        $err.CategoryInfo.Category,
        $dllpath
      )
      $PSCmdlet.ThrowTerminatingError( $eRecord )
    }
  }
  end {
    Write-Debug "`n$('-' * 80)`n-- End $($self.Name)`n$('-' * 80)"
  }
}
