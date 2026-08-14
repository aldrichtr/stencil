
using namespace System.IO
using namespace Scriban
using namespace Scriban.Parsing

function Convert-TemplateSource {
  <#
  .SYNOPSIS
    Convert template text into a Sriban.Template object
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
    [string]$Content,

    # The template language: Scriban (Default), Liquid, Scientific
    [Parameter(
    )]
    [ScriptLang]$Lang,

    # The parse Mode: Default, FrontMatterOnly, FrontMatterAndContent, or ScriptOnly
    [Parameter(
    )]
    [ScriptMode]$Mode

  )
  begin {
    $self = $MyInvocation.MyCommand
    Write-Debug "`n$('-' * 80)`n-- Begin $($self.Name)`n$('-' * 80)"
  }
  process {

    if (($PSBoundParameters.ContainsKey('Lang')) -or
        ($PSBoundParameters.ContainsKey('Mode'))) {

    }
    $template = [Template]::new()

    switch ($PSCmdlet.ParameterSetName) {
      'AsPath' {
        if (Test-Path $Path -PathType Leaf) {
          try {
            $result = $template.Parse([File]::ReadAllText($Path), $Path)
          } catch {
            Write-TerminatingError -ErrorRecord $_ -Message 'There was an error converting the template'
          }
        }
      }
      'AsText' {
        if ($Content.Length -gt 0) {
          $result = $template.Parse($Content)
        } else {
          Write-Error "Empty Content" -ErrorAction Stop
        }
      }
      default {
        Write-Error "No template content given" -ErrorAction Stop
      }
    }

    if ($result.HasErrors) {
      foreach ($e in $result.Messages) {
        Write-Error $e -ErrorAction Continue
      }
    } else {
      $result
    }
  }
  end {
    Write-Debug "`n$('-' * 80)`n-- End $($self.Name)`n$('-' * 80)"
  }
}
