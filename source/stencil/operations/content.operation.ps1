
$private:options = @{
  Name        = 'content'
  Description = 'Write content to a file'
  ScriptBlock = {
    param($params)
    Write-Debug "  -- Looking for path in $($current_job.env.SourcePath)"
    if ($params.Append) {
      'Adding Content {0} to {1}' -f $params.Value, $params.Path | Write-Debug
      $params.Remove('Append')
      Add-Content @params
    } else {
      'Setting Content {0} to {1}' -f $value, $params.Path | Write-Debug
      if ($null -ne $params.Append) {
        $params.Remove('Append')
      }
      Set-Content @params
    }
  }
}

Register-StencilOperation @private:options
