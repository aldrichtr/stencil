

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
