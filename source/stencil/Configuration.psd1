@{
    Registry = @{
        Path = "$PSScriptRoot\..\operations"
        Filter = "*.operation.ps1"
    }
    Default = @{
        StencilFile = 'stencil.yml'
        Directory   = '~/.stencil'
    }
    Parser = @{
        Ordered = $false
        UseMergingParser = $true
        AllDocuments = $true
    }
}
