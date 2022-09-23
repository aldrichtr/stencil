
#synopsis: remove the modules from memory
task remove_modules {
    foreach ($mod in $Modules.Keys) {
        Write-Build DarkBlue "  Checking for $mod"
        if (-not($null -eq (Get-Module $mod))) {
            Write-Build DarkBlue "  Removing $mod module"
            Remove-Module -Name $mod -Force -ErrorAction SilentlyContinue
        }
    }
}
#synopsis: delete the modules from disk
task uninstall_module remove_modules, {
    foreach ($mod in $Modules.Keys) {
        Write-Build DarkBlue "  Checking for $mod"
        if (-not($null -eq (Get-Module $mod))) {
            Write-Build DarkBlue "  Removing $mod module"
            Uninstall-Module -Name $mod -Force -ErrorAction SilentlyContinue
        }
    }
}

#synopsis: Remove items in the Clean property
task remove_clean_items  {
    $Clean.options | ForEach-Object {
        Write-Build DarkBlue "  Removing $($_.Path)"
        assert (-not([System.IO.Path]::GetRelativePath($BuildRoot, $_.Path) -match '^\.\.'))  "$($_.Path) is outside the project!"
        Get-ChildItem @_ | Remove-Item -Recurse -Force
    }
}
