
function Add-InstallModuleTask {
    param(
        [Parameter(
            Position = 0,
            Mandatory
        )]
        [string]$Name,

        [Parameter(
            Position = 1
        )]
        [string]$Target = 'CurrentUser'
    )

    task $Name -Data $PSBoundParameters -Source $MyInvocation {
        if ((Get-PackageSource | Select-Object -ExpandProperty Name) -contains $Project.Name) {
            Get-PackageSource -Name $Project.Name | Find-Package | ForEach-Object {
                switch ($Data.Target) {
                    'CurrentUser' {
                        $_ | Install-Package -Scope CurrentUser
                    }
                    'AllUsers' {
                        $_ | Install-Package -Scope AllUsers
                    }
                    Default {
                        if (Test-Path $Target) {
                            $_ | Save-Package -Path $Target
                        }
                    }
                }
            }
        }
    }
}

Set-Alias install_module Add-InstallModuleTask
