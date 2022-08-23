
function Invoke-Stencil {
    [CmdletBinding()]
    param(
        # Path to the stencil
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [Alias('PSPath')]
        [string[]]$Path
    )
    begin {
        Write-Debug "-- Begin $($MyInvocation.MyCommand.Name)"
    }
    process {
        foreach ($p in $Path) {
            try {
                $config_file = Join-Path $p 'stencil.psd1' -Resolve
                $config = Import-Psd $config_file -Unsafe
                foreach ($task in $config.Keys) {
                    $options = $config[$task]
                    switch ($task) {
                        'copy' {
                            "Copy {0} to {1}" -f ($options.Path -join ', '),
                                                  $options.Destination | Write-Debug
                            Copy-Item @options
                            continue
                        }
                        'new' {
                            "Creating {0} {1}" -f $options.ItemType , $options.Path | Write-Debug
                            New-Item @options
                            continue
                        }
                        'content' {
                            $options.Value = $ExecutionContext.InvokeCommand.ExpandString($options.Value)
                            if ($options.Append) {
                                "Adding Content {0} to {1}" -f $options.Value, $options.Path | Write-Debug
                                $options.Remove('Append')
                                Add-Content @options
                            } else {
                                "Setting Content {0} to {1}" -f $options.Value, $options.Path | Write-Debug
                                $options.Remove('Append')
                                Set-Content @options
                            }
                            continue
                        }
                        'read' {
                            Set-Variable -Name $options.Name -Value (Read-Host $options.Prompt)
                            continue
                        }
                        'expand' {
                            Invoke-EpsTemplate @options
                            continue
                        }
                        default {
                            "command '$task' is not internal.  Lookup in dynamic tasks"
                        }
                    }
                }
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }
    }
    end {
        Write-Debug "-- End $($MyInvocation.MyCommand.Name)"
    }
}
