Register-StencilOperation 'tree' {
    param($params)
    function createTree {
        param(
            [string]$root,
            [object]$tree
        )
        foreach ($sub in $tree.Keys) {
            Write-Debug "       Creating directory '$sub' in '$root'"
            New-Item -Path $root -ItemType Directory -Name $sub
            if ($sub.Keys.Count -gt 0) {
                Write-Debug "       '$sub' has $($sub.keys.count) child directories"
                createTree (Join-Path $root $sub), $tree.$sub
            }
        }
    }

    $start = $params.root
    Write-Debug "  Creating directory tree starting in $start"
    $params.Remove('root')
    createTree -root $start -tree $params
}
