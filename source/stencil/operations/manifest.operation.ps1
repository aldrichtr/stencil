
Register-StencilOperation 'manifest' {
    param($params)

    New-ModuleManifest @params
} -Description "Create a new module manifest at the given path"
