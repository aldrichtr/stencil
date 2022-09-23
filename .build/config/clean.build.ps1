param(
    <#
    The Clean task loops through each 'Option' hashtable and calls remove-item with it
    #>
    [Parameter()]
    [hashtable]$Clean = (
        property Clean @{
            Options = @(
                @{
                    Path    = $Project.Path.Artifact
                    Exclude = 'modules'
                }
                @{
                    Path = $Project.Path.Staging
                }
            )
        }
    )
)
