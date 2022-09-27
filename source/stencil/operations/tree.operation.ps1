Register-StencilOperation 'tree' {
    param($params)
    function createTree {
        param(
            [string]$root,
            [object]$tree
        )
        foreach ($key in $tree.Keys) {
            Write-Debug "       Creating directory '$key' in '$root'"
            New-Item -Path $root -ItemType Directory -Name $key
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
    $params.Remove('root')
    createTree -root $start -tree $params
}
