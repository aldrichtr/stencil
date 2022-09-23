task new_markdown_help {
    assert (Test-Path $Project.Path.Docs) "Docs folder not configured. Run 'Configure' task before this one"
    Write-Build DarkBlue "  Creating markdown help files in $($Project.Path.Docs)"

    foreach ($key in $Modules.Keys) {
        Import-Module (Resolve-Path $Modules[$key].StagingManifest) -Force

        <#HACK:
          In order to generate a "Module page", I need to pass in `-WithModulePage`.  And if I want to add
          the onlineversionurl I need to supply the `-Command`, However they cannot be used together.
          So, I'm running `New-MarkdownHelp` twice.  The first time to make the module page, and the second
          time for each command that has the `-Force` set to overwrite them
        #>
        assert(
            (Get-ChildItem -Path (
                Join-Path $Project.Path.Docs $key
            ) -Filter '*.md' -ErrorAction 'SilentlyContinue'
                ).Count -eq 0) 'Markdown help would be overwritten'
        Write-Build DarkBlue '  - Generating markdown help pages and a module page'
        New-MarkdownHelp -Module $key -WithModulePage -OutputFolder (Join-Path $Project.Path.Docs $key) -Force

        foreach ($cmd in (Get-Command -Module $key | Select-Object -ExpandProperty Name)) {
            $doc_options = @{
                Force                 = $true
                Command               = ''
                OutputFolder          = (Join-Path $Project.Path.Docs $key)
                AlphabeticParamsOrder = $true
                ExcludeDontShow       = $true
                OnlineVersionUrl      = -join ($GitRepo.OriginUrl, '/main/blob/', $Project.Path.Docs, '/', $key, '/')
                Encoding              = [System.Text.Encoding]::UTF8
            }
            $doc_options.Command = $cmd
            $doc_options.OnlineVersionUrl += "$cmd.md"
            Write-Build DarkBlue "   - Updating the $cmd help file metadata"
            New-MarkdownHelp @doc_options
        }
    }
}

task update_markdown_help {
    assert (Test-Path $Project.Path.Docs) "Docs folder not configured. Run 'Configure' task before this one"
    Write-Build DarkBlue "  Creating markdown help files in $($Project.Path.Docs)"

    foreach ($key in $Modules.Keys) {
        Import-Module (Resolve-Path $Modules[$key].StagingManifest) -Force


        foreach ($cmd in (Get-Command -Module $key | Select-Object -ExpandProperty Name)) {
            $doc_options = @{
                Path                  = (Join-Path $Project.Path.Docs $key "$cmd.md")
                AlphabeticParamsOrder = $true
                UpdateInputOutput     = $true
                ExcludeDontShow       = $true
                LogPath               = (Join-Path $Project.Path.Artifact "platyps_$(Get-Date -Format 'yyyy.MM.dd.HH.mm').log")
                Encoding              = [System.Text.Encoding]::UTF8
            }

            Write-Build DarkBlue " - Updating help for $cmd"
            Update-MarkdownHelp @doc_options
        }
    }
}

task stage_external_help {
    assert (Test-Path $Project.Path.Docs) "Docs folder not configured. Run 'Configure' task before this one"
    Write-Build DarkBlue "  Creating markdown help files in $($Project.Path.Docs)"

    foreach ($key in $Modules.Keys) {

        Write-Build DarkBlue " Generating the external help for '$key' from the docs in $($Project.Path.Docs) folder"
        New-ExternalHelp (Join-Path $Project.Path.Docs $key) -OutputPath (
            Join-Path $Modules[$key].Staging' en-US') -Force | Out-Null
    }
}
