

#synopsis: create a temporary repository named after the Project
task register_project_repo {
    if ((Get-PackageSource | Select-Object -ExpandProperty Name) -notcontains $Project.Name) {
        $repo_path = Join-Path $Project.Path.Artifact $Project.Name
        if (-not(Test-Path $repo_path)) { mkdir $repo_path -Force | Out-Null }
        $local_repo = @{
            Name            = $Project.Name
            SourceLocation  = $repo_path
            PublishLocation = $repo_path
            InstallationPolicy = 'trusted'
            <#ProviderName    = 'PowerShellGet'#>
        }
        Write-Build DarkBlue (
            '  Registering PackageSource {0} at {1}' -f $local_repo.Name, $local_repo.PublishLocation
        )
        $register = Register-PSRepository @local_repo | Out-String
        Write-Build DarkGray $register
    }
}

#synopsis: unregister the temporary repo
task unregister_project_repo {
    Write-Build DarkBlue "  Unregistering PackageSource $($Project.Name)"
    if ((Get-PackageSource | Select-Object -ExpandProperty Name) -contains $Project.Name) {
        Unregister-PackageSource -Name $Project.Name
    }
}

#synopsis: Generate a nuget package from the files in Staging.
task generate_nuget_package {
    assert ((Get-PackageSource | Select-Object -ExpandProperty Name) -contains $Project.Name) "No Package Source $($Project.Name)"
    foreach ($key in $Modules.Keys) {
        Write-Build DarkBlue "  Publishing $key to Repository $($Project.Name)"
        $options = @{
            Path       = $Modules[$key].Staging
            Repository = $Project.Name
        }
        Publish-Module @options
    }
}

#synopsis: publish module in the local system repository (psrepo == Local)
task publish_to_local_repo {
    assert ((Get-PackageSource | Select-Object -ExpandProperty Name) -contains 'local') "No local system repository found"
    Write-Build DarkGray "Checking for a recent package in the Artifact directory"
    $found =  Get-ChildItem (Join-Path $Project.Path.Artifact $Project.Name) -Filter "$($Project.Name)*.nupkg"
    switch ($found.Count) {
        0 {
            foreach ($key in $Modules.Keys) {
                Write-Build DarkBlue "  Publishing $key to local system repository"
                $options = @{
                    Path       = $Modules[$key].Staging
                    Repository = 'Local'
                }
                Publish-Module @options
            }
        }
        default {
            $dest = Get-PSRepository Local | Select-Object -ExpandProperty PublishLocation
            $found | Copy-Item -Destination $dest
        }
    }
}
