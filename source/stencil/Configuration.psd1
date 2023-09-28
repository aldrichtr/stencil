@{
    Registry = @{
        Path   = @(
            "$PSScriptRoot\operations",
            '~/.stencil/operations'
        )
        Filter = '*.operation.ps1'
    }
    Default  = @{
        StencilFile = 'stencil.yml'
        Directory   = '~/.stencil/jobs'
    }
    Parser   = @{
        Ordered          = $false
        UseMergingParser = $true
        AllDocuments     = $true
    }

    Template = @{
        TagStyle        = 'default'

        TagStyleMap     = @{
            default = @('<%', '%>', '%')
        }

        Whitespace      = '~'
        AddFinalNewLine = $false

        FrontMatter     = @{
            Ordered          = $false
            UseMergingParser = $false
            AllDocuments     = $false
        }
    }
}
