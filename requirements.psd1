@{
    PSDependOptions = @{
        Target = 'CurrentUser'
    }

    stitch = @{
        Tags = @(
            'ci',
            'Testing'
        )
        Version = '0.1.1'
        Parameters = @{
            AllowPreRelease = $true
        }
    }

    InvokeBuild = @{
        Tags = @(
            'ci',
            'publish'
        )
        Version = '5.10.3'
    }

    Configuration = @{
        Tags = @(
            'publish'
        )
        Version = '1.5.1'
    }

    BurntToast = @{
        Tags = @(
            'publish'
        )
        Version = '0.8.5'
    }

    Metadata = @{
        Tags = @(
            'publish'
        )
        Version = '1.5.7'
    }
    Pester = @{
        Tags = @(
            'ci',
            'Testing'
        )
        Version = '5.4.0'
    }
    PSDKit = @{
        Tags = @(
            'ci',
            'publish'
        )
        Version = '0.6.2'
    }

}
