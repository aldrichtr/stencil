
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
        [string]$Scope = 'CurrentUser'
    )

    task $Name -Source $MyInvocation -Data:@{ Scope = $Scope }{
        if ([string]::IsNullorEmpty($Data)) {
            $Data = @{
                Scope = 'CurrentUser'
            }
        }

        if ((Get-PackageSource | Select-Object -ExpandProperty Name) -contains $Project.Name) {
            Get-PackageSource -Name $Project.Name | Find-Package | ForEach-Object {
                $package = $_
                switch ($Data.Scope) {
                    'CurrentUser' {
                        $package | Install-Package -Scope CurrentUser
                    }
                    'AllUsers' {
                        $package | Install-Package -Scope AllUsers
                    }
                    Default {
                        if (Test-Path $Scope) {
                            $package | Save-Package -Path $Scope
                        }
                    }
                }
            }
        }
    }
}

Set-Alias install_module Add-InstallModuleTask
