
$private:options = @{
  Name        = 'copy'
  Command     = 'Copy-Item'
  Description = 'Copy Items from source to destination'
}

Register-StencilOperation @private:options
