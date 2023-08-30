function Get-SourceFilePath {
    [CmdletBinding()]
    param(
        # The test file to get the source file for
        [Parameter(
        )]
        [string]$TestFile
    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    process {
        <#
        we want to go from
        'tests/Unit/module1/public/Get-TheThing.Tests.ps1' to
        'source/module1/public/Get-TheThing.ps1'
        #>
        Write-Debug "`n$('-' * 80)`n-- Process start $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
        $sourceFile = $TestFile -replace '\.Tests\.ps1', '.ps1'
        Write-Debug "Now `$sourceFile is $sourceFile"
        $sourceFile = $sourceFile -replace '[uU]nit[\\\/]', ''
        Write-Debug "Now `$sourceFile is $sourceFile"
        $sourceFile = $sourceFile -replace 'tests' , 'source'
        Write-Debug "Now `$sourceFile is $sourceFile"
        Write-Debug "`n$('-' * 80)`n-- Process end $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    end {
        $sourceFile
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}

function Get-TestDataPath {
    <#
    .SYNOPSIS
        Return the data directory associated with the test
    #>
    [CmdletBinding()]
    param(
        # The test file to get the data directory for
        [Parameter(
        )]
        [string]$TestFile
    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    process {
        $testFileItem = Get-Item $TestFile
        $currentDirectory = $testFileItem.Directory
        $commandName = $testFileItem.BaseName -replace '\.Tests', ''
        $dataDirectory = (Join-Path $currentDirectory "$commandName.Data")
    }
    end {
        $dataDirectory
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}

function Resolve-Dependency {
    <#
    .SYNOPSIS
        Attempt to find the file for the resource requested
    .DESCRIPTION
        Provide a means for a test to lookup the path to a needed function, class , etc.
    .EXAMPLE
        $myTest = 'Test-MyItem' | Resolve-Dependency
        if ($null -ne $myTest) {
            . $myTest
        }
    #>
    [CmdletBinding()]
    param(
        # Name of the function or resource
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [string]$Name
    )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    process {
        $sourceItem = Get-SourceItem | Where-Object Name -Like $Name -ErrorAction SilentlyContinue
        if ($null -ne $sourceItem) {
            $sourceItem.Path
        }
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}

function Get-TestData {
    [CmdletBinding()]
    param(
        # The test file to get the data for
        [Parameter(
        )]
        [string]$TestFile
    )

    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    process {
        $dataDir = Get-TestDataPath
        if (-not ([string]::IsNullorEmpty($dataDir))) {
            Get-ChildItem -Path $dataDir
        }
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
