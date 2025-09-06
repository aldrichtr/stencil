
using namespace System.Collections
using namespace System.Collections.ObjectModel
using namespace System.Management.Automation.Host

Register-StencilOperation 'choice' {
  <#
  .SYNOPSIS
    Present options to the runner
  #>
  param($params)
  if ($params.ContainsKey('MultiChoice')) {
    $multiChoice = $params.MultiChoice
  } else {
    $multiChoice = $false
  }

  if (-not ($params.ContainsKey('Default'))) {
    $params['Default'] = -1
  }
  Write-Debug "$($params | ConvertTo-Psd | Out-String)"
  $choiceCollection = [Collection[ChoiceDescription]]::new()
  $values = [ArrayList]::new()
  $count = 0
  foreach ($choice in $params.choices) {
    if (-not ([string]::IsNullorEmpty($choice.label))) {
      $label = $choice.label | Expand-StencilValue -Data $Job
    } else {
      throw "Label missing from choice $($count + 1) for Job $($state.CurrentJob)"
    }
    if (-not ([string]::IsNullorEmpty($choice.help))) {
      $help = $choice.help | Expand-StencilValue -Data $Job
    } else {
      throw "Help missing from choice $($count + 1) for Job $($state.CurrentJob)"
    }
    if (-not ([string]::IsNullorEmpty($choice.value))) {
      $value = $choice.value | Expand-StencilValue -Data $Job
      [void]$values.Add($value)
    } else {
      throw "Value missing from choice $($count + 1) for Job $($state.CurrentJob)"
    }
    $choiceObject = [ChoiceDescription]::new($label, $help)
    [void]$choiceCollection.Add($choiceObject)
    $values.Insert($count, $value)
    $count++
  }

  $return = @{
    Values   = [ArrayList]::new()
    Indicies = [ArrayList]::new()
  }
  $title = "Select value for `${output.$($params.Name)}"
  if ($multiChoice) {
    $selections = $Host.UI.PromptForChoice($title, $params.Prompt, $choiceCollection, $params.Defaults)
    foreach ($selection in $selections) {
      Write-Debug "Adding $($values[$selection]) to return"
      [void]$return.Values.Add($values[$selection])
      Write-Debug "Adding $selection index to return"
      [void]$return.Indicies.Add($selection)
    }
  } else {
    $selection = $Host.UI.PromptForChoice($title, $params.Prompt, $choiceCollection, $params.Defaults)
    Write-Debug "Adding $($values[$selection]) to return"
    [void]$return.Values.Add($values[$selection])
    Write-Debug "Adding $selection index to return"
    [void]$return.Indicies.Add($selection)
  }
  if ($params.ContainsKey('Name')) {
    if ($Job.output.ContainsKey($params.Name)) {
      Write-Debug "Creating output.$($params.Name) key"
      Write-Debug "- with data $($return | ConvertTo-Psd | Out-String )"
      $Job.output.($params.Name) = $return
    } else {
      [void]$Job.output.Add($params.Name, $return)
    }
  } else {
    $return
  }
}
