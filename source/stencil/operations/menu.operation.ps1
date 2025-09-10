
$private:options = @{
  Name        = 'menu'
  Description = 'Present a menu of options to the user'
  ScriptBlock = {
    param($params)
    $return = Show-Menu $params.Options

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
}

Register-StencilOperation @private:options
