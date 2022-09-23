@{
    PSDependOptions = @{
        Target = 'out\modules'
        AddToPath = $true
        Parameters = @{
            Repository = 'PSGallery'
        }
    }


    #region BuildSystem
    InvokeBuild = @{
        Version = '5.9.11'
        Tags    = 'dev', 'ci'
    }

    ModuleBuilder = @{
        Version = 'latest'
        Tags    = 'dev', 'ci'
    }

    ChangelogManagement = @{
        Version = 'latest'
        Tags    = 'dev', 'ci'
    }

    Pester  = @{
        Version = '5.3.3'
        Tags    = 'dev', 'ci'
    }

    Assert = @{
        Version = '0.9.5'
        Tags    = 'dev', 'ci'
    }

    PSScriptAnalyzer = @{
        Version = '1.20.0'
        Tags    = 'dev', 'ci'
    }
    #endregion BuildSystem

    #region stencil requirements

    # Module configuration system
    Configuration = @{
        Version = '1.5.1'
        Tags    = 'prod', 'ci'
    }

    # Use yaml syntax in stencil files
    'powershell-yaml' = @{
        Version = '0.4.2'
        Tags    = 'prod', 'ci'
    }

    # The template system for flexible, configurable Output
    EPS = @{
        Version = '1.0.0'
        Tags    = 'prod', 'ci'
    }

    # Provides colors, emojis and symbols to Output
    Pansies = @{
        Version = '2.6.0'
        Tags    = 'prod', 'ci'
        # This module wants to "Clobber" `Write-Host`, which personally, I think is a good thing....
        Parameters = @{
            AllowClobber = $true
            AllowPrerelease = $true
        }
    }
    #endregion stencil requirements

}
