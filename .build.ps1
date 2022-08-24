param(
    [Parameter()]
    [string]$ProjectName = (property ProjectName 'stencil')
)

# synopsis: set up the environment for building the project
task Configure {
    Invoke-PSDepend -Tags @('dev')
}

# synopsis: create a temporary repository named after the Module
task Register {
    $repo_path = Join-Path $BuildRoot "out\$ProjectName"
    if (-not(Test-Path $repo_path)) { mkdir $repo_path -Force | Out-Null }
    $local_repo = @{
        Name         = $ProjectName
        Location     = $repo_path
        Trusted      = $true
        ProviderName = 'PowerShellGet'
    }
    Write-Build DarkBlue ("  Registering PackageSource {0} at {1}" -f $local_repo.Name, $local_repo.Location)
    Register-PackageSource @local_repo | Out-Null
}

# synopsis: unregister the temporary repo
task Unregister {
    Write-Build DarkBlue "  Unregistering PackageSource $ProjectName"
    if ((Get-PackageSource | Select-Object -ExpandProperty Name) -contains $ProjectName) {
        Unregister-PackageSource -Name $ProjectName
    } else {
        Write-Build DarkRed "  $ProjectName not found in PackageSources"
    }
}

# synopsis: a nuget package from the files in Staging.
task Package Register, {
    if ((Get-PackageSource | Select-Object -ExpandProperty Name) -contains $ProjectName) {
        $staging_dir = Join-Path $BuildRoot "stage\$ProjectName"
        Write-Build DarkBlue "  Publishing $ProjectName to $staging_dir"
        Publish-Module -Path $staging_dir -Repository $ProjectName
    }
}, Unregister
#endregion Local Repository

#region Uninstall

# synopsis: remove the module from memory and delete from disk
task Uninstall {
    if (-not($null -eq (Get-Module $ProjectName))) {
        Write-Build DarkBlue "  Removing $ProjectName module"
        Remove-Module -Name $ProjectName -Force
        Uninstall-Module -Name $ProjectName -Force
    }
}
#endregion Uninstall

# synopsis: Remove files from selected directories
task Clean Uninstall, {
    $options = @(
        @{
            Path = "$BuildRoot\out\*"
            Exclude = 'modules'
        }
        @{
            Path = "$BuildRoot\stage\*"
        }
    )
    $options | ForEach-Object {
        Write-Build DarkBlue "  Removing $($_.Path)"
        Get-ChildItem @_ | Remove-item -Recurse -Force
    }
}

# synopsis: Build the module (psm1), manifest and any supporting files
task Stage {
    $options = @{
        SourcePath = "$BuildRoot\source\stencil\stencil.psd1"
        VersionedOutputDirectory = $true
        OutputDirectory = '..\..\stage'
    }

    Write-Build DarkBlue "  Staging the module to $(Join-Path $options.SourcePath $options.OutputDirectory)"
    Build-Module @options
}

# synopsis: Run the Pester tests in the Unit directory
task UnitTest {
    import-module "$BuildRoot\source\stencil\stencil.psm1" -Force
    Write-Build DarkBlue "  Running Pester tests in $BuildRoot\tests\Unit"
    $conf = New-PesterConfiguration
    $conf.Run.Path = "$BuildRoot\tests\Unit"
    $conf.Filter.ExcludeTag = @('analyzer')
    $conf.Output.Verbosity = 'Detailed'
    Invoke-Pester -Configuration $conf
}
