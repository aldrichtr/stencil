

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

#synopsis: Copy any items identified in the 'Copy' key of the Module
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

#synopsis: Add current updates to CHANGELOG.md and ReleaseNotes in the manifest
task generate_release_notes {
    $gv = gitversion | ConvertFrom-Json
    $ver = $gv.FullSemVer
    foreach ($key in $Modules.Keys) {
        if ($Modules[$key].Root) {
            $root = $Modules[$key]
        }
    }
    write-build DarkGray "Creating Changelog for version $ver"

    Write-Build DarkGray "  Moving changes to new release section"
    $options = @{
        Path = "$BuildRoot\CHANGELOG.md"
        ReleaseVersion = $ver
        LinkMode = 'Automatic'
        LinkPattern = @{
            FirstRelease  = "https://github.com/aldrichtr/stencil/tree/v{CUR}"
            NormalRelease = "https://github.com/aldrichtr/stencil/compare/v{PREV}..v{CUR}"
            Unreleased    = "https://github.com/aldrichtr/stencil/compare/v{CUR}..HEAD"
        }
   }
   Update-Changelog @options
   Remove-Variable options

   Write-Build DarkGray "  Staging changelog for version $ver"

   $options = @{
    Path = "$BuildRoot\CHANGELOG.md"
    OutputPath = (Join-Path $root.Staging 'CHANGELOG.md')
    Format = 'Release'
   }
   ConvertFrom-Changelog @options
   Remove-Variable options

   Write-Build DarkGray "  Creating Release Notes"
   $changes = Get-ChangelogData -Path (Join-Path $root.Staging 'CHANGELOG.md')

   $options = @{
    Path = (Join-Path $root.Staging 'CHANGELOG.md')
    OutputPath = (Join-Path $root.Staging 'ReleaseNotes.md')
    Format = 'Release'
    NoHeader = $true
   }
   ConvertFrom-Changelog @options
   Remove-Variable options

   Write-Build DarkGray "   - Adding notes to staging manifest"
   $release_notes = Get-Content (Join-Path $root.Staging 'ReleaseNotes.md') -Raw
   Update-Metadata -Path $root.StagingManifest -Property ReleaseNotes -Value $release_notes
}
