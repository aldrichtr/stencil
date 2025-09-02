
<#
tree: Create a directory tree based on the hashtable keys given
params: root, hashtable
#>

Register-StencilOperation 'tree' {
    param($params)
    function createTree {
        param(
            [string]$root,
            [object]$tree
        )
        foreach ($key in $tree.Keys) {
            Write-Debug "       Creating directory '$key' in '$root'"
            try {
                $item = New-Item -Path $root -ItemType Directory -Name $key
                Write-Verbose "Created $($item.FullName)"
            }
            catch {
                $message = "Could not create directory $root/$key"
                $exceptionText = ( @($message, $_.ToString()) -join "`n")
                $thisException = [Exception]::new($exceptionText)
                $eRecord = New-Object System.Management.Automation.ErrorRecord -ArgumentList (
                    $thisException,
                    $null,  # errorId
                    $_.CategoryInfo.Category, # errorCategory
                    $null  # targetObject
                )
                $PSCmdlet.ThrowTerminatingError( $eRecord )
            }
            $sub = $tree[$key]
            if ($sub.Keys.Count -gt 0) {
                Write-Debug "       '$key' has $($sub.Keys.Count) child directories"
                createTree -root (Join-Path $root $key) -tree $sub
            } else {
                Write-Debug "       '$key' does not contain any child directories"
            }
        }
    }

    $start = $params.root
    Write-Debug "  Creating directory tree starting in $start"
    [void]$params.Remove('root')
    createTree -root $start -tree $params
} -Description 'Create a directory tree based on the hashtable keys given'
