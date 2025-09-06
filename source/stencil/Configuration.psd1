@{
    Registry = @{
        Path = "$PSScriptRoot\operations"
        Filter = "*.operation.ps1"
    }
    Default = @{
        StencilFile = 'stencil.yml'
        ValuesFile  = 'defaults.yml'
        Path        = @{
            Root       = "$env:APPDATA\DevKit"
            Jobs       = 'jobs'
            Operations = 'operations'
        }
    }
    Parser   = @{
        Ordered          = $false
        UseMergingParser = $true
        AllDocuments = $true
    }
}
