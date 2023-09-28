
task remove.test.output.files {
    remove (Join-Path $Artifact "tests\*")
}
