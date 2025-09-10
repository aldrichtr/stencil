
<#
new:  Create Items in the given path
params: ApplicationName, Authentication, CertificateThumbprint, ConnectionURI, Credential,
        Force, ItemType, Name, Options, OptionSet, Path, Port, SessionOption, UseSSL,
        Value, Confirm, WhatIf

#>
$private:options = @{
  Name        = 'new'
  Description = 'Create Items in Path'
  Command     = 'New-Item'
}

Register-StencilOperation @private:options
