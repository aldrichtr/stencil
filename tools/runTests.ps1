param(
     [string]$ConfigurationPath,

    [string]$Type = 'Unit'
 )

$root = Resolve-ProjectRoot
if ($null -eq $root) {
    $root = (Get-Location).Path
}

$testsFolder = (Join-Path $root 'tests')

if (Test-Path $testsFolder) {
    Import-Module "$testsFolder\TestHelpers.psm1"
}

if ([string]::IsNullOrEmpty($ConfigurationPath)) {
    $ConfigurationPath = (Join-Path -Path (Find-BuildConfigurationDirectory -BuildProfile 'default') -ChildPath 'Pester')
}

$ConfigurationName = "${Type}Tests.config.psd1"

$ConfigurationPath = (Join-Path $ConfigurationPath $ConfigurationName)

if (Test-Path $ConfigurationPath) {
    Write-Verbose "Loading test configuration from $ConfigurationPath"
    $configInfo = Import-Psd $ConfigurationPath -Unsafe
    $pesterConfiguration = New-PesterConfiguration -Hashtable $configInfo
} else {
    $pesterConfiguration = New-PesterConfiguration
    $pesterConfiguration.Run.Path = "tests\$Type"
}

Invoke-Pester -Configuration $pesterConfiguration
