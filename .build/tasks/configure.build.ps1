
#synopsis: Install modules required for developing powershell modules
task install_dependencies {
    Write-Host '  Ensuring PSDepend2 is available before proceeding' -NoNewline -ForegroundColor Gray
    if (Get-InstalledModule PSDepend2) {
        Write-Host '  Done' -ForegroundColor DarkGreen
    } else {
        Write-Host '  Failed' -ForegroundColor DarkRed
        Write-Host '  Installing PSDepend2 in CurrentUser Scope' -ForegroundColor Blue
        Install-Module PSDepend2 -Scope CurrentUser
    }
    Write-Build Gray '  Checking dependencies for dev environment:'

    ## Test-Dependency adds 'DependencyExists' to each object
    $deps = (Get-Dependency @Dependencies | Test-Dependency)
    $missing = @()
    $targets = @()
    foreach ($dep in $deps) {
        if ($targets -notcontains $dep.Target) { $targets += $dep.Target }
        $output = '   - {0} ({1})' -f $dep.DependencyName, $dep.Version
        if ($dep.DependencyExists) {
            Write-Build DarkGreen $output
        } else {
            $missing += $dep
            Write-Build DarkGray $output
        }
    }

    if ($missing.Count -gt 0) {
        Write-Build DarkBlue "  $($missing.Count) dependencies not met.  Calling Invoke-PSDepend"
        Invoke-PSDepend @Dependencies -Force -Verbose
    } else {
        Write-Build DarkGreen '  All dependencies met'
        Write-Build DarkGray '  Checking the Target option for the dependencies'
        $mod_paths = ([Environment]::GetEnvironmentVariable('PSModulePath') -split ';')

        foreach ($target in $targets) {
            switch ($target) {
                'CurrentUser' { continue }
                'AllUsers' { continue }
                Default {
                    $target_path = $target | Resolve-Path
                    if (Test-Path $target_path) {
                        Write-Build DarkGray "  Looking for $target in PSModulePath"
                        if ($mod_paths -contains $target_path) {
                            Write-Build DarkGreen "   $target already set"
                        } else {
                            Write-Build Cyan "   Adding $target"
                            $new_mod_paths =  "$target_path;$($mod_paths -join ';')"
                            [Environment]::SetEnvironmentVariable('PSModulePath', ($new_mod_paths -join ';'))
                        }
                    } else {
                        Write-Build DarkYellow "  Skipping $target_path because it does not exist"
                    }
                }
            }
        }
    }
}


#synopsis: Create any missing directories
task create_directories {
    if ($null -ne $Project.Path) {
        foreach ($key in $Project.Path.Keys) {
            $projPath = $Project.Path[$key]
            if (Test-Path $projPath) {
                Write-Build Gray (
                    ' - {0,-16} {1}' -f $key,
                        ((Get-Item $projPath) |
                        Resolve-Path -Relative -ErrorAction SilentlyContinue)
                )
            } else {
                New-Item $projPath -ItemType Directory
                Write-Build DarkBlue (' - {0,-16} {1}' -f $key, "added missing $projPath" )
            }
        }
    }
}
