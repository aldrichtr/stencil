
using namespace System.Collections

function Get-Template {
  <#
  .SYNOPSIS
    Get all templates in the configured directories
  #>
  [CmdletBinding()]
  param(
    # The name of the template to return
    [Parameter(
      Position = 0
    )]
    [string]$Name,

    # The prefix of the templates to return
    [Parameter(
    )]
    [string]$Prefix,

    # Do not include `common` templates
    [Parameter(
      DontShow
    )]
    [switch]$NoCommon,

    # Return a hashtable instead of a Template.TemplateInfo object
    [Parameter(
    )]
    [switch]$AsHashTable
  )
  begin {
    $self = $MyInvocation.MyCommand
    Write-Debug "`n$('-' * 80)`n-- Begin $($self.Name)`n$('-' * 80)"
    $modConfig = Get-ProfileConfiguration -key 'template'
    $sep = '[/|\\]'
    $pathComponents = @('Prefix', 'Category')
  }
  process {
    $root = Resolve-TemplateDirectory
    Write-Debug "Starting in root directory: $root"

    # SECTION Get template files

    $fileOptions = @{
      Path    = $root
      Recurse = $true
      Include = ($modConfig.Extensions.Values |
          ForEach-Object { "*$_" })
    }
    $templateFiles = Get-ChildItem @fileOptions
    # !SECTION

    :file foreach ($file in $templateFiles) {
      Write-Debug "- file: $($file.Name)"
      $definition = (Get-Content -Path $file.FullName -Raw)
      $fm = $definition | Get-TemplateFrontMatter

      $type = $modConfig.Extensions.GetEnumerator() |
        Where-Object Value -Like $file.Extension |
          Select-Object -ExpandProperty Key

      Write-Debug '  - Processing $type file'


      $templateInfo = @{
        PSTypeName = 'Templates.TemplateInfo'
        Path       = $file.FullName
        Type       = $type
        Definition = $definition
        Name       = $file.BaseName
        Delimiters = $fm.Delimiters
        Imports    = $fm.Imports
      }

      # SECTION Convert folders to metadata
      $rel = ($file | Resolve-Path -Relative -RelativeBasePath $root)
      ## remove the leading `./` from the path
      $rel = $rel -replace "^\.$sep"
      ## remove the trailing `/filename.ext`
      $rel = $rel -replace ('{0}{1}' -f $sep, [regex]::Escape($file.Name))
      [ArrayList]$parts = $rel -split $sep
      Write-Debug "Splitting path $rel into $($parts -join ', ')"

      $parts.Reverse()
      [Stack]$stack = $parts
      Write-Debug "Stack has $($stack.Count) items"

      :fields for ($i=0; $i -lt $pathComponents.Count; $i++) {
        $fieldName = $pathComponents[$i]
        if ($stack.Count -gt 0) {
          $templateInfo[$fieldName] = $stack.Pop()
        } else {
          break fields
        }
      }
      # !SECTION


      # SECTION Return the object or table

      ## Skip this file if it doesn't match `Name`
      if ($PSBoundParameters.ContainsKey('Name')) {
        if ($templateInfo.Name -notlike $Name) {
          continue file
        }
      }

      ## Skip this file if it doesn't match `Prefix`
      if ($PSBoundParameters.ContainsKey('Prefix')) {
        if ($templateInfo.Prefix -notlike $Prefix) {
          continue file
        }
      }

      if ($AsHashTable) {
        $templateInfo
      } else {
          [PSCustomObject]$templateInfo
        }
      # !SECTION
    }
  }
  end {
    Write-Debug "`n$('-' * 80)`n-- End $($self.Name)`n$('-' * 80)"
  }
}
