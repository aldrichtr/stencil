

#synopsis: Update the version in the source module
task update_source_manifest_version {
    $version_info = dotnet-gitversion | ConvertFrom-Json

    foreach ($key in $Modules.Keys) {
        $man = Test-ModuleManifest $Modules[$key].SourceManifest

        $previous_version = $man.Version
        $current_version = $version_info.MajorMinorPatch

        Write-Build DarkBlue "$CurrentIndent Updating source module from $previous_version to version $current_version"
        Update-Metadata -Path $man.Path -PropertyName 'ModuleVersion' -Value $current_version
    }
}

#synopsis: Update the version information in the Markdown help
task update_doc_help_version {
    $version_info = dotnet-gitversion | ConvertFrom-Json
    $current_version = $version_info.MajorMinorPatch

    Get-ChildItem $Project.Path.Docs -Filter '*.md' | ForEach-Object {
        if (Select-String -Path $_ -Pattern '^Help Version:') {
            Write-Build DarkBlue "$CurrentIndent Updating help $($_.Name) to version $current_version"
            (Get-Content $_) -replace '^Help Version: .*' , "Help Version: $current_version" |
                Set-Content -Path $_ -Encoding UTF8NoBOM
        }
    }
}

#synopsis: Update the version information in the README file
task update_readme_version {
    $version_info = dotnet-gitversion | ConvertFrom-Json
    $current_version = $version_info.MajorMinorPatch
    $readme = Join-Path $BuildRoot 'README.md'
    Write-Build DarkBlue "$CurrentIndent Updating Readme to version $current_version"
    (Get-Content $readme) -replace '^Version: .*', "Version: $current_version" |
        Set-Content -Path $readme -Encoding UTF8NoBOM
}

#synopsis: Increment the version using gitversion
task bump_version {
    Write-Build DarkBlue "Ensuring we are on the main branch"
    Set-GitHead main
    $gv = gitversion | ConvertFrom-Json
    foreach ($key in $Modules.Keys) {
        if ($Modules[$key].Root) {
            $root = $Modules[$key]
        }
    }
    assert ($null -ne $root) "Could not find the root module"
    Write-Build DarkBlue "Bump version to $($gv.FullSemVer) in $($root.SourceManifest)"
    Update-Metadata -Path $root.SourceManifest -Value $gv.FullSemVer

    assert ((Test-ModuleManifest $root.SourceManifest).Version -eq $gv.FullSemVer) "Module version not updated"

    Write-Build DarkBlue "Adding new version"
    Add-GitItem $root.SourceManifest
    Save-GitCommit -Message "build: bump version to $($gv.FullSemVer)"

    Write-Build DarkBlue "Tagging our new version"
    New-GitTag -Name "v$($gv.FullSemVer)"

    Write-Build DarkBlue "Pushing changes to $(Get-GitBranch -Current | Select-Object -ExpandProperty RemoteName)"
    Get-GitBranch -Current | Send-GitBranch
}
