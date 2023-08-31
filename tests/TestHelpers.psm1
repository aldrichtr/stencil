#Requires -Modules @{ ModuleName = 'stitch'; ModuleVersion = '0.1' }
function Get-SourceFilePath {
    [CmdletBinding()]
    param()
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    process {
        $callStack = Get-PSCallStack
        $caller = $callStack[1]
        $testFileName = Split-Path $caller.ScriptName -LeafBase
        if (-not ([string]::IsNullorEmpty($testFileName))) {
            $sourceName = $testFileName -replace '\.Tests', ''
            $sourceItem = Get-SourceItem
            | Where-Object Name -Like $sourceName -ErrorAction SilentlyContinue
        } else {
            $PSCmdlet.ThrowTerminatingError($_)
        }
        if ($null -ne $sourceItem) {
            $sourceItem.Path | Write-Output
        } else {
            throw "Could not find source item for $sourceName"
        }
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}

function Get-TestDataPath {
    <#
    .SYNOPSIS
        Return the data directory associated with the test
    #>
    [CmdletBinding()]
    param( )
    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    process {
        $callStack = Get-PSCallStack
        $caller = $callStack[1]
        if ($caller.ScriptName -like $callStack[0].ScriptName) {
            $caller = $callStack[2]
        }

        $dataDirectory = ($caller.ScriptName -replace '\.Tests\.ps1', '.Data')
        if (-not ([string]::IsNullorEmpty($dataDirectory))) {
            $dataDirectory | Write-Output
        } else {
            throw "Could not determine the data directory"
        }
    }
    end {
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
        # The filter to apply (as a script block)
        [Parameter(
        )]
        [scriptblock]$Filter
    )

    begin {
        Write-Debug "`n$('-' * 80)`n-- Begin $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
    process {
        $dataDir = Get-TestDataPath
        if (-not ([string]::IsNullorEmpty($dataDir))) {
            if (-not ([string]::IsNullorEmpty($Filter))) {
                Get-ChildItem -Path $dataDir
                | Where-Object $Filter
            } else {
                Get-ChildItem -Path $dataDir
            }
        } else {
            throw "Could not find data Directory for $((Get-PSCallStack)[1].ScriptName) "
        }
    }
    end {
        Write-Debug "`n$('-' * 80)`n-- End $($MyInvocation.MyCommand.Name)`n$('-' * 80)"
    }
}
