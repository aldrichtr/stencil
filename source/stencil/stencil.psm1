using namespace System.Collections
using namespace System.Io


  <#
.SYNOPSIS
  Generic Development-Mode PowerShell Script Module
.DESCRIPTION
  This module file is intended to be used during development to load all of the
  files in the directories in this module folder.
  By default, The module will "dotsource" all .ps1 files, "use" all .psm1 files,
  and "load" all .psd1 files in the source directories.
  The order of loading is the alphabetical sort that comes from a call to *Get-ChildItem*,
  unless a file named `LoadOrder.txt` is found in the same directory as this file.
  ## LOAD ORDER
  That file should list files, in the desired load order, blank lines and lines starting
  with a '#' are ignored.  Files should be listed as relative to this module file.  Once
  those files are loaded, the loading continues with any other files that were not already
  listed.
#>
  # SECTION: Header
  $private:templateInfo = @{
    Name     = 'Source module template'
    Version  = '0.7.3'
    Modified = '2026-04-09 14:01:56'
  }

  $private:modulePath = $PSCommandPath
  $private:moduleName = ($private:modulePath | Split-Path -Leaf)

try {

  if ($env:__PSMODULE_DEBUG -eq $true) {
    $DebugPreference = 'Continue' # "Switch on" Write-Debug messages
    $private:__save_pref = @{
      Debug    = $DebugPreference
      Verbose  = $VerbosePreference
      Progress = $ProgressPreference
    }
  }


  #! if debug was turned on, we need to see it and pass it into this scope
  if ($global:DebugPreference -like 'Continue') {
    $script:DebugPreference = 'Continue'
    @(
      ('=' * 80),
      '= Debugging on ',
      "= Loading $private:moduleName from $private:modulePath"
      ('=' * 80)
      "= -- Using $($private:templateInfo.Name) $($private:templateInfo.Version) ($($templateInfo.Modified))"
      ('=' * 80)
    ) | Write-Debug
  }
  # !SECTION: Header

  # SECTION: Options

  $private:sourceDirectories = @(
    'enum',
    'classes',
    'private',
    'public'
  )

  $private:formatsOptions = @{
    Path    = (Join-Path $PSScriptRoot 'formats')
    Filter  = '*.Formats.ps1xml'
    Recurse = $true
  }

  $private:typesOptions = @{
    Path    = (Join-Path $PSScriptRoot 'types')
    Filter  = '*.Types.ps1xml'
    Recurse = $true
  }

  $private:prefixFile = (Join-Path $PSScriptRoot 'prefix.ps1')
  $private:suffixFile = (Join-Path $PSScriptRoot 'suffix.ps1')

  $private:importOptions = @{
    Path        = $PSScriptRoot
    Filter      = '*.ps*1'
    Recurse     = $true
    ErrorAction = 'Stop'
  }
  # !SECTION: Options

  [ArrayList]$private:sourceFiles = $private:sourceDirectories | ForEach-Object {
    $private:importOptions.Path = (Join-Path $PSScriptRoot $_)
    Get-ChildItem @private:importOptions | ForEach-Object { [Path]::GetRelativePath($PSScriptRoot, $_ ) }
  }

  Write-Debug "$($sourceFiles.Count) Source files found"

  # SECTION: Prefix file
  if ($prefixFile | Test-Path) {
    Write-Debug "Loading prefix file $prefixFile"
    . $prefixFile
    [void]$sourceFiles.Remove([Path]::GetRelativePath($PSScriptRoot, $_))
  }
  # !SECTION: Prefix file

  # SECTION: Custom Load Order
  if (Test-Path "$PSScriptRoot\LoadOrder.txt") {
    Write-Debug 'Using custom load order'
    try {
      foreach ($line in (Get-Content "$PSScriptRoot\LoadOrder.txt")) {
        switch -Regex ($line) {
          # blank line, skip
          '^\s*$' { continue }
          # Comment line, skip
          '^\s*#$' { continue }
          # load these
          '\.ps1$' {
            $filePath = (Join-Path $PSScriptRoot $line)
            if (Test-Path $filePath) {
              Write-Debug "Sourcing file $line"
              . $filePath
              $sourceFiles.Remove($line)
            }
            # TODO: What should we do if the file doesn't exist?
            continue
          }
          # modules get treated special
          '\.psm1$' {
            $filePath = (Join-Path $PSScriptRoot $line)
            if (Test-Path $filePath) {
              Write-Debug "Using the module $line"
              $useBlock = [scriptblock]::Create("using module $filePath")
              $useBlock.Invoke()
            }
            $sourceFiles.Remove($line)
            continue
          }
          # manifest gets loaded
          '\.psd1$' {
            $filePath = (Join-Path $PSScriptRoot $line)
            if (Test-Path $filePath) {
              Write-Debug "Importing manifest $line"
              Import-Module $filePath -Global -Force
            }
            $sourceFiles.Remove($line)
          }
          #unrecognized, skip
          default { continue }
        } ## end switch
      } ## end ForEach

    } catch {
      Write-Error "Custom load order $_"
    }
  }
  # !SECTION: Custom Load Order

  Write-Debug "$($sourceFiles.Count) Source files found"

  # SECTION: Load files
  $private:remainingFiles = $sourceFiles.Clone()
  try {
    foreach ($private:file in $remainingFiles) {
      $private:currentFile = (Join-Path $PSScriptRoot $file)
      if ($currentFile -match '\.ps1$') {
        Write-Debug "Sourcing file $file"
        . $currentFile
        [void]$sourceFiles.Remove($file)
      } elseif ($file -match '\.psm1$') {
        Write-Debug "Using module $($currentFile)"
        $private:useStmt = [scriptblock]::Create("using module $currentFile")
        . $useStmt
        [void]$sourceFiles.Remove($file)
      } elseif ($currentFile -match '\.psd1$') {
        Write-Debug "Importing manifest $currentFile"
        Import-Module $currentFile -Global -Force
        [void]$sourceFiles.Remove($file)
      } else {
        Write-Debug "Ignoring file $file"
      }
    }
  } catch {
    throw "An error occurred during the processing of file '$file':`n$_"
  }
  # !SECTION: Load files

  # SECTION: Format files
  if ($private:formatsOptions.Path | Test-Path) {
    foreach ($private:formatFile in (Get-ChildItem @private:formatsOptions)) {
      Write-Debug "Adding Formats from $($private:formatFile.Name)"
      Update-FormatData -AppendPath $private:formatFile.FullName
    }
  }
  # !SECTION: Format files

  # SECTION: Type files
  if ($private:typesOptions.Path | Test-Path) {
    foreach ($private:typeFile in (Get-ChildItem @private:typesOptions)) {
      Write-Debug "Adding types from $($private:typeFile.Name)"
      Update-TypeData -AppendPath $private:typeFile
    }
  }
  # !SECTION: Type files

  # SECTION: Suffix file
  if ($private:suffixFile | Test-Path) {
    Write-Debug "Loading suffix file $private:suffixFile"
    . $private:suffixFile
    Write-Debug "Loading prefix file $suffixFile"
    . $suffixFile
    [void]$sourceFiles.Remove([Path]::GetRelativePath($PSScriptRoot, $suffixFile))
  }
  # !SECTION: Suffix file

}

finally {
  $DebugPreference = $private:__save_pref.Debug
  $VerbosePreference = $private:__save_pref.Verbose
  $ProgressPreference = $private:__save_pref.Progress
}
