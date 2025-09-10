
$private:options = @{
  Name = 'manifest'
  Command = 'New-ModuleManifest'
  Description = "Create a new module manifest at the given path"
}

Register-StencilOperation @private:options
