

#synopsis: Use Build-Module to create an unversioned module and supporting files for testing
module build_staging_module -Stage

#synopsis: Use Build-Module to create a versioned module and supporting files
module build_module

#synopsis: Import the staged module
task reload_module {
    foreach ($key in $Modules.Keys) {
        if (Get-Module $key) {
            Write-Build DarkGray "Removing $key from environment"
            Remove-Module $key
        }
        Write-Build DarkGray "Importing module $key"
        Import-Module $Modules[$key].Staging
    }
}

task copy_source_items {
    foreach ($key in $Modules.Keys) {
        $config = $Modules[$key]
        if ($config.Keys -contains 'Copy') {
            foreach ($item in $config.Copy) {
                $item.Destination = (Join-Path $config.Staging $item.Path)
                $item.Path = (Join-Path $config.Source $item.Path)
                Copy-Item @item
            }
        }
    }
}
